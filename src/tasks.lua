CompletedTasks = CompletedTasks or {}
PendingTasks = Tasks or {}

function get_initial_task_key(msg)
  return msg.Id
end

function get_existing_task_key(msg)
  return msg.TaskId
end

Handlers.add(
  "submit",
  Handlers.utils.hasMatchingTag("Action", "Submit"),
  function (msg)
    if msg.Type == nil then
      Handlers.utils.reply("Type is required")(msg)
      return
    end

    if msg.InputData == nil then
      Handlers.utils.reply("InputData is required")(msg)
      return
    end

    if msg.ComputeLimit == nil then
      Handlers.utils.reply("ComputeLimit is required")(msg)
      return
    end

    if msg.MemoryLimit == nil then
      Handlers.utils.reply("MemoryLimit is required")(msg)
      return
    end
    local task_key = get_initial_task_key(msg)
    PendingTasks[task_key] = {}
    PendingTasks[task_key].id = msg.Id
    PendingTasks[task_key].type = msg.TaskType
    PendingTasks[task_key].inputData = msg.InputData
    PendingTasks[task_key].computeLimit = msg.ComputeLimit
    PendingTasks[task_key].memoryLimit = msg.MemoryLimit
    Handlers.utils.reply(task_key)(msg)
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
    if msg.TaskId == nil then
      Handlers.utils.reply("TaskId is required")(msg)
      return
    end

    if msg.Result == nil then
      Handlers.utils.reply("Result is required")(msg)
      return
    end

    local task_key = get_existing_task_key(msg)
    CompletedTasks[task_key] = PendingTasks[task_key]
    CompletedTasks[task_key].result = msg.Result
    PendingTasks[task_key] = nil
    Handlers.utils.reply(task_key)(msg)
  end
)

Handlers.add(
  "getCompletedTasksById",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasksById"),
  function (msg)
    if msg.TaskId == nil then
      Handlers.utils.reply("TaskId is required")(msg)
      return
    end

    local task_key = get_existing_task_key(msg)
    local task = CompletedTasks[task_key]
    local encode_task = "[]"
    if task ~= nil then
      encoded_task = require("json").encode(task);
    end

    Handlers.utils.reply(encoded_task)(msg)
  end
)

Handlers.add(
  "getCompletedTasks",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasks"),
  function (msg)
    local tasks = require("json").encode(CompletedTasks);
    Handlers.utils.reply(tasks)(msg)
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetAllTasks"),
  function (msg)
    local all_tasks = {}
    if #PendingTasks > 0 then
      all_tasks.pendingTasks = PendingTasks
    end

    if #CompletedTasks > 0 then
      all_tasks.completedTasks = CompletedTasks
    end

    local encoded_tasks = require("json").encode(all_tasks)
    Handlers.utils.reply(encoded_tasks)(msg)
  end
)
