# Concurrent Julia
Julia prides itself on being a language that excels in terms of both development time and runtime. Researchers can write code that runs fast with minimal effort. One reason that Julia is fast for development is that there are few choices to make when it comes time to selecting packages, and, in many cases, no package is required because the Julia development team has prioritizes, builds and includes essential functionality for research developers in `Base`.

Parallel programming is a case-in-point. The term "parallel programming" encompasses a wide range. Julia supports three classical parallel programming paradigms  "out-of-the-box", while the Julia ecosystem provides tightly-integrated support for recent advances, e.g., accelerators and GPUs.

Before diving into Julia, let's briefly review three "classical" concurrent programming paradigms: multi-processed, multithreaded and asynchronous computing.

## Multiprocessing
Multiprocessing is the most familiar type of concurrent programming to researchers. It simply means running multiple *processes* in parallel. Processes do not share memory, so this sort of concurrency can scale to huge numbers of concurrent processes on a large cluster. On the other hand, because processes do not share memory, communication between processes is relatively slow, and their is a (relatively) high start-up cost associated with each process. For these reasons, multiprocessing is generally best suited to programs that need to perform many large, independent, CPU-bound operations.

### Multiprocessing in Julia
Multiprocessing functionality is provided by the `Distributed` module. Supplying the `-p [NUM_WORKERS]` option at start-up creates a process pool with `NUM_WORKERS` workers. You can also create or modify the pool *after* start-up using `Distributed.addprocs`.

```shell
julia -p 2
```

```julia
using Distributed
Distributed.addprocs(2)
```

Scheduling tasks to workers is performed with either `Distributed.remotecall` or `Distributed.@spawnat`:
```julia
r = remotecall(rand, 2, 2, 2)
s = @spawnat 3 1 .+ fetch(r)
fetch(s)
```
While `remotecall` takes a function as its argument, `@spawnat` takes an expression. The macro creates a closure around the expression and runs the closure on the specified worker. This means that, for example, that the `fetch(r)` above is run on worker 3, not the process where `@spawnat` is called.

Both `remotecall` and `@spawnat` return a `Future` object that relays information about the state of the job. You obtain the result of a computation by calling `fetch` on it. Note, however, that `fetch` blocks/waits until the result is ready. The `isready` method allows you to check if a result if ready before calling `fetch`.

Processes do not, in general, directly share data. Thus, worker processes do not have access to values created by the main process and vice-a-versa. Futhermore, worker processes do not know what code is available on the main process. In order to run code with dependencies, we need a mechanism for loading code on worker processes. That ability is provided by the `@everywhere` macro.

```julia
@everywhere using DataFrames
```

The `DataFrames` module is now in scope on all worker processes (and the main process).

Because data is not generally available on the process where work is scheduled, care must be taken to avoid unintended data movement. When a block of code is executed on a worker process, Julia implicitly copies values to the worker, which may or may not be what the develop intended (and can have serious performance consequences). For this reason, multiprocessing generally provides the largest speedups in cases that involve large computations and minimal back-and-forth of movement of data.

#### Useful
- `myid()` - return the executing process ID.
- `nworkers()` - return the number of process pool workers.
- `nprocs()` - return the number of processes, including the main process.
- `addprocs(np::Integer=Sys.CPU_THREADS)` - launch `np` workers.
- `rmprocs(pids)` - remote the specified workers.

#### Notes
- Workers are in addition to the main process, so the maximum worker ID is `NUM_WORKERS + 1`. You can see all these processes running if you check your activity monitor / list running processes.
- The `-p` option automatically loads the `Distributed` module.
- Using `-p auto` launches as many workers as logical cores available. On modern laptops, this might not be the expected number. For example, on a 12-core Mac Studio, Julia launches 8 workers because the M2 Max chips only have 8 "performance" cores (and no hyperthreading).

### Example: Job Queue
A job queue is a server that accepts requests to run programs or functions in process pool. When it receives a request, it places it in a FIFO queue. If there is a process available, the job is scheduled to run.

For example, here's the RQ package:

```python
def count_words(string):
    return len(string)

q = Queue(connection=Redis())
res = q.enqueue(count_words, 'You're a silly bean!')
```

In Julia, we can create an "internal" job queue at start-up using the `-p` option (or *after* start-up using the `Distributed.addprocs` function). But this isn't useful if we need run Julia *across* programs. Let's try re-implementing the RQ package, Julia style.

```julia
# On the first Julia REPL
using Redis

conn = RedisConnection() # requires running Redis server

id = 123
set(conn, 123, println("hello"))

# On the second Julia REPL
using Redis

conn = RedisConnection()

f = get(conn, 123) # typeof(f) == String
r = @spawnat eval(Meta.parse(f))
```

Cool! With a few lines of code we have the makings of a job queue. (Okay—so we have some issues to work out in terms of code availability, but I'm sure we can figure it out 😅).

### Parallel Maps
A common use of multiprocessing is to perform map-reduce (or just map) operations. Given a problem, we break the problem into "independent" parts that can be computed in parallel, i.e., we "map" a function over the components. Then, we combine—or "reduce"—the results with another function, such as `min`, `max`, `sum`, `mean`, etc. These types of calculations are so common that Julia includes *two* high-level methods to assist you: `pmap` and the `@distributed` macro.

```julia
# sum 200000000 random bits
res = @distributed (+) for i = 1:200000000
    Int(rand(Bool))
end

# perform f on each element of x
pmap(f, x)
```

Both methods only use worker processes for computation. Note that the reducer in `@distributed` is optional, but `pmap` provides a simpler interface in that case. In either case, any values used by the mapped function should be *read-only*. These values will be copied to the workers, and therefore all modifications/side effects will be local to the worker process.



## Multithreading
Multithreading is another familiar concurrent programming paradigm. As the name suggest, it uses multiple *threads* to perform actions simultaneously. Unlike processes, threads share memory space. Thus, multithreaded programs can efficiently share/pass information between operations. On the other hand, getting access to a large number of cores *and* memory may be challenging. In addition, having shared data means having to worry about *race conditions*. Writing "thread-safe" code (i.e., code free from race conditions) is notoriously difficult.

### Multithreading in Julia
- Julia provides multithreading support via the `Threads` module.
- There are two commonly used macros: `@threads` for multithreaded for-loops and `@spawn` for running tasks on a thread.
- In order to make use of `Threads`, we need to start Julia with a threadpool using the `-t` option:
```shell
julia -t 4
```
- This starts Julia with two threads, one of which is the main thread.
- The `-t` options can be combined with `-p` to start multiple multithreaded processes. 
- We can now schedule tasks to run in the threadpool using `@spawn`:
```julia
t = @spawn foo()
```
- The returned value is an awaitable `Task`.
- A common use of multiple threads is to run parallel for loops. Julia provides the `@threads` macro for this case:
```julia
@threads for i = 1:10
    # run a costly operations
end
```
- In many cases, these are the only tools needed to create parallelized Julia code.
- In more complicated cases, we need to worry about communication and data-race conditions.

#### Thread Safety
By "thread-safe" we mean that some code can run with risk of errors created by "data race conditions". A data-race condition exists whenver two threads can access and modify some data in a manner that might result in corrupted or incorrect results.

In Julia, *you* are responsible for ensuring programs are data-race free! Julia `Channel`s are thread-safe and may be used to communicate safely betwen threads. Most data, however, is not safe. `ReentrantLock` provides a mechanism for safely accessing and modifying data that is used by multiple threads. In order to manipulate a value, a thread acquires the lock, does some work and then releases the lock. While the lock is held, Julia prevents other threads from accessing any variable accessed.

- *NOTE*: use `$` to interpolate value instead of (possibly) passing a reference.
- Useful methods:
    - `Threads.nthreads`: get the number of threads.
    - `Threads.threadid`: get the ID of the current thread.
    - *WARNING* `threadid` cannot be considered constant per task because tasks can be moved across threads while yielding. Use the `:static` option for `@threads` freezes the thread ID.


- -p 2 -t 2 means two workers with two threads on each process
    - Use addprocs and pass -t as exeflags for fine-grained control
- Interactive threads?
- `Threads.@threads for i = 1:10`
- `Threads.@spawn` - like @async, but with threads running task
    - Multiple tasks can use the same thread!

# Threads
- -p 2 -t 2 means two workers with two threads on each process
    - Use addprocs and pass -t as exeflags for fine-grained control
- Interactive threads?
- `Threads.@threads for i = 1:10`
- `Threads.@spawn` - like @async, but with threads running task
    - Multiple tasks can use the same thread!

## Data-race conditions
- You are responsible for ensuring program is data-race free!
- Julia Channels are thread-safe => may be used to communicate safely betwen threads
- `ReentrantLock` provides a mechanism for safely accessing and modifying data that is used by multiple threads
- A thread acquires the lock, does some work and then releases the lock
- Julia prevents other threads from accessing any variable accessing while the lock is locked

### Atomics (cf. Dune)
- `Threads.Atomic` can wrap primitive types (`isprimitivetype(T) == true`)

## Asynchronous Programming
Asynchronous programming refers to code in which the program does not stop to execute (at least some) functions. For example, a function might "pause" to fetch data from an API, return control to a main event loop, then resume to perform an action after the data finishes downloading before finally exiting. Asynchronous programming is especially useful for application development because it provides a way to "move through" IO bound operation. This soft of programming is essential for graphical interfaces and browsers, but can also be useful when optimizing any IO-bound code, i.e., coed that spends a lot of time on "blocking" actions: database queries, API calls, background jobs, disk access, GPU, etc. (Essentially anything that depends on an "external" system).

At its core, however, async programming (within a process) is all about yielding executing. Normally, a function only pauses its execution to call another function:
```julia
function do_something()
    # start doing something...
    fetch_data()
    # keep doing something...
end
```
Here, the `fetch_data` function is added to the call stack, the function runs and eventually returns to `do_something` (and is removed from the call stack). If the code that follows `fetch_data` is not entirely dependent on its result, then we need not wait for it to return before continuing `do_something`. In order for that to happen, `fetch_data` must yield control back to `do_something`. When `fetch_data` completes its IO-bound operation, `do_something` can yield control *back* to `fetch_data` in order to (e.g.) format the data before finally returning.

### Asynchronous Julia

#### Highlights
- Suppose I want to create a user interface framework. A user interface requires an *event loop*.
- Most of the time, nothing is happening. When the user presses a button, the program performs an action. The action might pause the event loop or it might perform an asychronous action in the background. A Julia `Task` can perform actions that do not take up compute cycles "in the background", allowing the event loop to continue responding to new events while.
- `Task`s also allow you to schedule functions in arbitrary ways because tasks can be interrupted.
- "Switching tasks does not use any space so any number of task switches can occur without consuming the call stack."
- Create-start-run-finish life cycle

One thing that I would like to contrast (or figure out) is how Julia makes it easy or hard relatively to other languages to write this sort of code. In JavaScript and Python, they have the `async` function syntax that allows you to mark functions as running async:
```
async def foo():
    # do something possibly asynchronously
```
This function can run asynchronous code *and* other `async` functions can call it. In JavaScript, I just call this function and it runs asynchronously (because that is the default behavior); in Python, I have to do `asyncio.run(foo())`. In Julia, by contrast, I can turn any function *call* into a task using `@task` and then run it with `schedule`. Or create-and-run with `@async`.

As a concrete example, let's say that I need to fetch a result from an API.
```julia
using HTTP

function fetch(id)
    res = HTTP.request("GET", "http://awesome-research-tool.io/run/$id")
    return map(preprocess, res)
end
```
In Julia, this function does not need to be defined as asynchronous. It can simply be called asynchronously:
```julia
@async fetch(id)
```
The disadvantage of this might be that it is hard to tell what code might *benefit* from running asynchronously. In general, JavaScript and Python functions that are `async` can actually perform an async actions: in Julia, it isn't necessarily clear what function might benefit (e.g., how do we know the above example will "work").

#### Example - Event Loop
In this example, we'll create a simple "server" that handles requests. The server will be implemented as an event loop that continuously checks for requests in the form of messages passed via a `Channel`. When the server receives a request, it "executes" the request *asynchronous*, i.e., as a `Task`, and continue to check for new requests.
```julia
using Dates

struct Request
    id
    duration
    message
end

function (req::Request)()
    start = now()
    println("[$start] Starting request $(req.id) (duration=$(req.duration)).")
    sleep(req.duration)
    finish = now()
    dt = finish - start
    println("[$finish] From request $(req.id): $(req.message) (elapsed=$(dt.value / 1000)).")
end

function generate_requests(max_requests)
    n = 0
    while n < max_requests
        waittime = rand()
        sleep(waittime)
        req = Request(rand(1:128), 5.0 * rand(), "Hello!")
        put!(chnl, req)
        n += 1
    end
end

chnl = Channel{Request}(128)
Threads.@spawn generate_requests(6)
while true
    req = take!(chnl)
    @async req()
end

```

## Message Passing
- Julia uses channels to communicate between tasks, threads and processes.
- `Channel` is a waitable FIFO queue.
- Multiple tasks and connect to either end of the channel.
- Listeners and wait for values.
- 
There are two primary ways that threads communicate: by sharing state or by sending messages. Julia supports both approaches. Sending messages is somewhat easier to understand, so let's take a look at that. A `Channel` is a first-in-first-out ("FIFO") queue that contains an internal buffer. Senders `put!` values in the channel and receivers `take!` values from the channel. If the channel's buffer is full, then senders must wait ("block") until a spot opens up; if the channel's buffer is empty, then receivers must wait until a value is available. Creating a channel is straight-forward:

```julia
chnl = Channel{Int}(32)
```

The only argument is an integer size that determines how many items the channel can hold. The *type parameter* determines the type of item the channel can hold. In this case, our channel only accepts `Int` values. Omitting the type parameter results in channel that holds `Any` value, while omitting the size parameter results in a size-zero or "unbuffered channel"—senders must wait until a receiver requests a value to place their value in the channel (at which point it is immmediately consumed).

To send a "message", we simply `put!` a value on the channel:
```julia
val = 1
put!(chnl, val)
```

We can check if a channel has a value available with `isready`. To fetch the value, we can use `take!` to remove an item or `fetch` to return the value without removing it.

When we're done with the channel, we can `close` it to stop senders and receivers from using it. To automatically close a channel when a task completes, we can `bind` the task to the channel:
```julia
bind(chnl, task)
```

In terms of thread safety, passing messages this way serves as a way to denote the "owner" of data: when a sender places a value in the channel, it gives up ownership of that data (and the eventual receiver takes ownership).

## External Packages
In addition to the built-in support, there are a number of popular and useful community packages. Here are a few you may find useful:
- Dagger.jl
- CUDA.jl
- Metal.jl