CompletedTasks = CompletedTasks or {}
PendingTasks = Tasks or {}
Results = Results or {}

Handlers.add(
  "submit",
  Handlers.utils.hasMatchingTag("Action", "Submit"),
  function (msg)
    PendingTasks[msg.Id] = {}
    PendingTasks[msg.Id].id = msg.Id
    PendingTasks[msg.Id].type = msg.Type
    PendingTasks[msg.Id].inputData = msg.InputData
    PendingTasks[msg.Id].computeLimit = msg.computeLimit
    PendingTasks[msg.Id].memoryLimit = msg.memoryLimit
    Handlers.utils.reply(msg.Id)(msg)
  end
)

Handlers.add(
  "getPendingTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    
  end
)

-- msg.TaskId, msg.Result
Handlers.add(
  "reportResult",
  Handlers.utils.hasMatchingTag("Action", "ReportResult"),
  function (msg)
    
  end
)

Handlers.add(
  "getCompletedTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    
  end
)
