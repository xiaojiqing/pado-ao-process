CompletedTasks = CompletedTasks or {}
PendingTasks = Tasks or {}

function get_initial_task_key(msg)
  return msg.Id
end

function get_existing_task_key(msg)
  return msg.TaskId
end

function get_task_list(tasks)
  local result = {}
  for _, task in pairs(tasks) do
    table.insert(result, task)
  end
  return result
end

function get_encoded_task_list(tasks)
  local task_list = get_task_list(tasks)
  local encoded_list = require("json").encode(task_list)
  return encoded_list
end

Handlers.add(
  "submit",
  Handlers.utils.hasMatchingTag("Action", "Submit"),
  function (msg)
    if msg.TaskType == nil then
      Handlers.utils.reply("TaskType is required")(msg)
      return
    end

    if msg.Data == nil then
      Handlers.utils.reply("Data is required")(msg)
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
    PendingTasks[task_key].inputData = msg.Data
    PendingTasks[task_key].computeLimit = msg.ComputeLimit
    PendingTasks[task_key].memoryLimit = msg.MemoryLimit
    Handlers.utils.reply(task_key)(msg)
  end
)

Handlers.add(
  "getPendingTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    local encoded_tasks =  get_encoded_task_list(PendingTasks)

    Handlers.utils.reply(encoded_tasks)(msg)
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

    if msg.Data == nil then
      Handlers.utils.reply("Data is required")(msg)
      return
    end

    local task_key = get_existing_task_key(msg)
    CompletedTasks[task_key] = PendingTasks[task_key]
    CompletedTasks[task_key].result = msg.Data
    PendingTasks[task_key] = nil
    Handlers.utils.reply(task_key)(msg)
  end
)

Handlers.add(
  "getCompletedTaskById",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTaskById"),
  function (msg)
    if msg.TaskId == nil then
      Handlers.utils.reply("TaskId is required")(msg)
      return
    end

    local task_key = get_existing_task_key(msg)
    local task = CompletedTasks[task_key]
    local encode_task = "{}"
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
    local encoded_tasks = get_encoded_task_list(CompletedTasks) 
    Handlers.utils.reply(encoded_tasks)(msg)
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetAllTasks"),
  function (msg)
    local all_tasks = {}
    all_tasks.pendingTasks = get_task_list(PendingTasks)
    all_tasks.completedTasks = get_task_list(CompletedTasks)

    local encoded_tasks = require("json").encode(all_tasks)
    Handlers.utils.reply(encoded_tasks)(msg)
  end
)
