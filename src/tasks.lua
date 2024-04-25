CompletedTasks = CompletedTasks or {}
PendingTasks = PendingTasks or {}

function GetInitialTaskKey(msg)
  return msg.Id
end

function getExistingTaskKey(msg)
  return msg.TaskId
end

function getTaskList(tasks)
  local result = {}
  for _, task in pairs(tasks) do
    table.insert(result, task)
  end
  return result
end

function getEncodedTaskList(tasks)
  local taskList = getTaskList(tasks)
  local encodedList = require("json").encode(taskList)
  return encodedList
end

function convertToMap(list)
  local m = {}
  for index, item in ipairs(list) do
    m[item] = index
  end
  return m
end

function count(map)
  local num = 0
  for _, _ in pairs(map) do
    num = num + 1
  end
  return num
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
    
    if msg.ComputeNodes == nil then
      Handlers.utils.reply("ComputeNodes is required")(msg)
      return
    end
    local taskKey = GetInitialTaskKey(msg)
    PendingTasks[taskKey] = {}
    PendingTasks[taskKey].id = msg.Id
    PendingTasks[taskKey].type = msg.TaskType
    PendingTasks[taskKey].inputData = msg.Data
    PendingTasks[taskKey].computeLimit = msg.ComputeLimit
    PendingTasks[taskKey].memoryLimit = msg.MemoryLimit

    local computeNodeList = require("json").decode(msg.ComputeNodes)
    local computeNodeMap = convertToMap(computeNodeList)
    PendingTasks[taskKey].computeNodes = computeNodeMap
    Handlers.utils.reply(taskKey)(msg)
  end
)

Handlers.add(
  "getPendingTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    local encodedTasks =  getEncodedTaskList(PendingTasks)

    Handlers.utils.reply(encodedTasks)(msg)
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

    if msg.NodeName == nil then
      Handlers.utils.reply("NodeName is required")(msg)
      return
    end

    if msg.Data == nil then
      Handlers.utils.reply("Data is required")(msg)
      return
    end

    local taskKey = getExistingTaskKey(msg)
    local pendingTask = PendingTasks[taskKey]
    if pendingTask == nil then
      Handiers.utils.reply("PendingTasks " .. taskKey .. " not exist")
      return
    end

    if pendingTask.computeNodes[msg.NodeName] == nil then
      Handlers.utils.reply("NodeName not in ComputeNodes")(msg)
      return
    end
    PendingTasks[taskKey].result = PendingTasks[taskKey].result or {}
    PendingTasks[taskKey].result[msg.NodeName] = msg.Data
    PendingTasks[taskKey].computeNodes[msg.NodeName] = nil
    if count(PendingTasks[taskKey].computeNodes) == 0 then
      CompletedTasks[taskKey] = PendingTasks[taskKey]
      CompletedTasks[taskKey].computeNodes = nil
      PendingTasks[taskKey] = nil
    end
    Handlers.utils.reply(taskKey)(msg)
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

    local taskKey = getExistingTaskKey(msg)
    local task = CompletedTasks[taskKey]
    local encodedTask = "{}"
    if task ~= nil then
      encodedTask = require("json").encode(task);
    end

    Handlers.utils.reply(encodedTask)(msg)
  end
)

Handlers.add(
  "getCompletedTasks",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasks"),
  function (msg)
    local encodedTasks = getEncodedTaskList(CompletedTasks) 
    Handlers.utils.reply(encodedTasks)(msg)
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetAllTasks"),
  function (msg)
    local allTasks = {}
    allTasks.pendingTasks = getTaskList(PendingTasks)
    allTasks.completedTasks = getTaskList(CompletedTasks)

    local encodedTasks = require("json").encode(allTasks)
    Handlers.utils.reply(encodedTasks)(msg)
  end
)
