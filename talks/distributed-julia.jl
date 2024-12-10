# Distributed Julia

"""
There are three types of "distributed" programming made available in Julia:

1. Multi-processing
2. Multi-threading
3. Asynchronous Programming (tasks/coroutines)

These correspond to:

1. Multiple processes
2. Multiple threads
3. Multiplexing

Processes have their own memory, so (1) is a distributed memory model. Threads share memory, so (2) is
a shared memory model. (Multiplexing applies to a single process, so their is no memory to share).
"""

## Asynchronous
"""
- Create three request generators.
- The generators send messages to main process at random intervals via a Channel.
- The "server" handles the messages in tasks that sleep for the requested time

"""


using Dates

MAX_WAITTIME = 5.0
MAX_DURATION = 3.0

struct Request
    sender::Int64
    duration::Float64
end

sender(req::Request) = req.sender
duration(req::Request) = req.duration

function run(req::Request)
    println("[$(now())] Request from $(sender(req)) started (duration=$(duration(req))).")
    sleep(duration(req))
    println("[$(now())] Request from $(sender(req)) finished.")
end

mutable struct Generator
    n::Int64
    max_requests::Int64
end

Generator() = Generator(0, 6)

Base.count(gen::Generator) = gen.n
Base.size(gen::Generator) = gen.max_requests
function increment!(gen::Generator)
    gen.n += 1
end

function run(gen::Generator, chnl::Channel{Request})
    while count(gen) < size(gen)
        sleep(MAX_WAITTIME * rand())
        req = Request(rand(1:4896), MAX_DURATION * rand())
        put!(chnl, req)
        increment!(gen)
    end
end

function run(gen::Generator)
    while count(gen) < size(gen)
        sleep(MAX_WAITTIME * rand())
        req = Request(rand(1:4896), MAX_DURATION * rand())
        @async run(req)
        increment!(gen)
    end
end

struct Server
    chnl::Channel{Request}
    max_tasks::Int64
end

function run(server::Server)
    while true
        req = take!(server.chnl)
        @async run(req)
    end
end


# TODO: Make a new type of generator that makes server print out timestamps every N seconds.

# generator = Generator()
# run(generator)

chnl = Channel{Request}(32)

server = Server(chnl, 128)
Threads.@spawn run(server)

generator = Generator()
Threads.@spawn run(generator, chnl)


## Mutli-threading
"""
An idea here would be 
"""

## Multi-processing
"""
An idea here would be to make a process pool that accepts "jobs". When a job arrives, it runs that
job on available process.
"""

### Low-level
"""
- Start Julia with -p to use multiple processes (this automatically loads Distributed)
    - N is the number of additional workers
    - auto launches as many workers as the number of CPU *threads*
        - CAUTION! This didn't work on my Mac Studio (8 workers != 24). Interestingly, the M2 Max chips have 8 performance cores and 4 efficiency cores (performance has larger L1, L2 cache). Julia seems to discover the performance cores only.
    - If you check activity monitor, you'll see N + 1 julia processes; N are child processes of the main process
    - This means that you can assign work to IDs 1.. N + 1 (ID = 1 is the main process)
    - You can do all this after start-up, too, using Distributed.addprocs


- The main process is always assigned ID = 1; worker processes are ID = 2, 3,...
- Use @everywhere to load modules on worker processes; this does *not* bring the module into scope on workers!
- Futures cache their value locally.
- @async ?

- In general, data needs to be moved to the process where computation is assign. This is costly, and needs to be
considered when writing low-level distributed code. There are not always good answers. If the answer is bad,
it might mean that the problem is not well-suited to distributed compute. (My feeling is that distributed compute
is usually best suited for problems that are independent, including in regards to the required data).
- Global variables are messy...TODO

- myid()
- nworkers()
- addworker()

"""
using Distributed
r = remotecall(rand, 2, 2, 2) # Future
s = @spawnat 2 1 .+ fetch(r) # Future, use :any to assign to any available process, fetch is performed on the process running the operation—is this always the case?
fetch(s)
remotecall_fetch(rand, 2, 2, 2) # fetch(remotecall(rand, 2, 2, 2)) - why is this faster?

### High-level
"""
- @distributed does not require a reducer; it returns a Task if none is provided
    - If no reducer used, consider using pmap instead
    - Variables used within the loop must be copied to workers
        - Modifying the copies does not modify the original! Workers have their *own* copies => no side effects!
            - Read-only is perfectly fine, but you will still pay cost of copying data.
        - Caveat: it's perfectly allowable to have side effects *outside* of Julia.
    - You don't have to reduce, e.g., if the loop only has side effects
- SharedArrays
    - This is the mechanism available for side effects with processes. It isn't really recommended. If you need
      SharedArray, use multi-threading.
- @sync is used to wait for all Futures to be done, e.g. @sync @distributed ...
- Both pmap and @distributed only use *worker* processes
- pmap for large work; @distributed for small tasks?
"""
res = @distributed (+) for i = 1:200000000
    Int(rand(Bool))
end

pmap(f, x...) # apply f to each value of array x


## External Packages
- Dagger.jl
- CUDA.jl
- Metal.jl