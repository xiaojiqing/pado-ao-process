CompletedTasks = CompletedTasks or {}
PendingTasks = Tasks or {}

Handlers.add(
  "submit",
  Handlers.utils.hasMatchingTag("Action", "Submit"),
  function (msg)
    PendingTasks[msg.Id] = {}
    PendingTasks[msg.Id].id = msg.Id
    PendingTasks[msg.Id].type = msg.Type
    PendingTasks[msg.Id].inputData = msg.Data
    PendingTasks[msg.Id].computeLimit = msg.ComputeLimit
    PendingTasks[msg.Id].memoryLimit = msg.MemoryLimit
    Handlers.utils.reply(msg.Id)(msg)
  end
)

Handlers.add(
  "getPendingTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    Send({ Target = msg.From, Data = require('json').encode(PendingTasks) })
  end
)

-- msg.TaskId, msg.Result
Handlers.add(
  "reportResult",
  Handlers.utils.hasMatchingTag("Action", "ReportResult"),
  function (msg)
    CompletedTasks[msg.TaskId] = PendingTasks[msg.TaskId]
    CompletedTasks[msg.TaskId].result = msg.Result
    PendingTasks[msg.TaskId] = nil
    Handlers.utils.reply(msg.TaskId)(msg)
  end
)

Handlers.add(
  "getCompletedTasksById",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasksById"),
  function (msg)
    
  end
)

Handlers.add(
  "getCompletedTasks",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasks"),
  function (msg)
    
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetAllTasks"),
  function (msg)
    
  end
)
