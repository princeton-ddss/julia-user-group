# Distributed Julia



## Asynchronous
function do_something(t)
    println("Starting to wait.")
    sleep(5) # stops execution
    print("Done.")
end

t = @task do_something(3) # create task
schedule(t) # start task
wait(t) # wait for task to finish (interrupts the calling task/process)
@async do_something(3) # create-and-start task

function producer(c::Channel)
    put!(c, "start")
    for n = 1:4
        put!(c, 2n)
    end
    put!(c, "stop")
end

chnl = Channel(producer) # create a channel with a task running producer bound to it
# i.e., something like chnl = Channel(); @async producer(chnl)
take!(chnl) # block until a value is available
# this is bit confusing because the channel always seems to have just one value
# available. So the task is pausing between calls to take!? Yes—this is because 
# chnl is unbuffered, i.e., a Channel(0), which means that put! calls block until
# a take! is received

# can use in for loop!
for val in Channel(producer)
    println(val)
end

# errormonitor(task) # print to stderr if task fails (is this really useful? there is already a stacktrace printed to stderr in this case, so this is a duplicate other than the ERROR: bit)

# - if channel is empty, readers block until an item becomes available
# - if channel is full, writers block until space becomes available
# - isready
# - Channel starts open; use `close` to close it. You can continue emptying the channel.  
# - fetch retrieves values without removing them
# - yieldto(task, value) is the only primitive needed to switch between tasks!
# - current_task, istaskdone, istaskstarted, task_local_storage
# - "Most task switches occur as a result of waiting for events such as I/O requests, and are performed by a scheduler included in Julia Base."

function do_work(task_id)
    for job_id in jobs
        println("[$(time())] Starting job $job_id on task $task_id")
        sleep(3.0)
        println("[$(time())] Finished job $job_id on task $task_id")
    end
end

const jobs = Channel{Int}(32)

for job_id in 1:12
    put!(jobs, job_id)
end

for task_id in 1:3
    @async do_work(task_id)
end


## Multi-processing

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
-Dagger.jl
-CUDA.jl
-Metal.jl