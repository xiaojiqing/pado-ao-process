CompletedTasks = CompletedTasks or {}
PendingTasks = PendingTasks or {}

local bint = require('.bint')(256)

function GetInitialTaskKey(msg)
  return msg.Id
end

function getExistingTaskKey(msg)
  return msg.Tags.TaskId
end

function getTaskList(tasks)
  local result = {}
  for _, task in pairs(tasks) do
    table.insert(result, task)
  end
  return result
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
    if msg.Tags.TaskType == nil then
      replyError(msg, "TaskType is required")
      return
    end

    if msg.Tags.DataId == nil then
      replyError(msg, "DataId is required")
      return
    end

    if msg.Data == nil then
      replyError(msg, "Data is required")
      return
    end

    if msg.Tags.ComputeLimit == nil then
      replyError(msg, "ComputeLimit is required")
      return
    end

    if msg.Tags.MemoryLimit == nil then
      replyError(msg, "MemoryLimit is required")
      return
    end
    
    if msg.Tags.ComputeNodes == nil then
      replyError(msg, "ComputeNodes is required")
      return
    end
    local taskKey = GetInitialTaskKey(msg)
    PendingTasks[taskKey] = {}
    PendingTasks[taskKey].id = msg.Id
    PendingTasks[taskKey].type = msg.Tags.TaskType
    PendingTasks[taskKey].inputData = msg.Data
    PendingTasks[taskKey].computeLimit = msg.Tags.ComputeLimit
    PendingTasks[taskKey].memoryLimit = msg.Tags.MemoryLimit
    PendingTasks[taskKey].computeNodes = msg.Tags.ComputeNodes
    PendingTasks[taskKey].from = msg.From
    PendingTasks[taskKey].nodeVerified = false
    PendingTasks[taskKey].dataVerified = false
    PendingTasks[taskKey].tokenVerified = false
    PendingTasks[taskKey].msg = msg

    ao.send({Target = NODE_PROCESS_ID, Tags = {Action = "GetComputeNodes", ComputeNodes = msg.Tags.ComputeNodes, UserData = taskKey}}) 
    ao.send({Target = DATA_PROCESS_ID, Tags = {Action = "GetDataById", DataId = msg.Tags.DataId, UserData = taskKey}})
    ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "Balance", Recipient = msg.From, UserData = taskKey}})

    --local computeNodeList = require("json").decode(msg.Tags.ComputeNodes)
    --local computeNodeMap = convertToMap(computeNodeList)
    --PendingTasks[taskKey].computeNodeMap = computeNodeMap
    --PendingTasks[taskKey].verifyingNodes = computeNodeList

    replySuccess(msg, taskKey)
  end
)

Handlers.add(
  "getComputeNodesSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Success"),
  function (msg)
    local dataMap = require("json").decode(msg.Data)
    local taskKey = dataMap.userData
    local computeNodeMap = dataMap.data
    local originMsg = PendingTasks[taskKey].msg
    PendingTasks[taskKey].computeNodeMap = computeNodeMap
    PendingTasks[taskKey].nodeVerified = true

    local theTask = PendingTasks[taskKey]
    if theTask.nodeVerified and theTask.dataVerified and theTask.tokenVerified then
      if bint.__le(theTask.dataPrice, theTask.tokenBalance) then
        ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "TransferFrom", Sender = theTask.from, Recipient = ao.id, Quantity = theTask.dataPrice, UserData = taskKey}})
      else
        PendingTasks[taskKey] = nil
        replyError(originMsg, "Insufficient Balance")
      end
    end
  end
)

Handlers.add(
  "getComputeNodesError",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes-Error"),
  function (msg)
    local errorMap = require("json").decode(msg.Tags.Error)
    local taskKey = errorMap.userData
    local errorMsg = errorMap.errorMsg
    if PendingTasks[taskKey] ~= nil then
      local originMsg = PendingTasks[taskKey].msg
      PendingTasks[taskKey] = nil

      replyError(originMsg, "Verify compute nodes error: " .. errorMsg)
    end
  end
)

Handlers.add(
  "getDataByIdSuccess",
  Handlers.utils.hasMatchingTag("Action", "GetDataById-Success"),
  function (msg)
    local dataMap = require("json").decode(msg.Data)
    local taskKey = dataMap.userData
    local data = dataMap.data
    local dataPrice = require("json").decode(data.price)
    local originMsg = PendingTasks[taskKey].msg
    PendingTasks[taskKey].dataPrice = dataPrice.price
    PendingTasks[taskKey].priceSymbol = dataPrice.symbol
    PendingTasks[taskKey].dataVerified = true
    PendingTasks[taskKey].dataProvider = data.from

    local theTask = PendingTasks[taskKey]
    if theTask.nodeVerified and theTask.dataVerified and theTask.tokenVerified then
      if bint.__le(theTask.dataPrice, theTask.tokenBalance) then
        ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "TransferFrom", Sender = theTask.from, Recipient = ao.id, Quantity = theTask.dataPrice, UserData = taskKey}})
      else
        PendingTasks[taskKey] = nil
        replyError(originMsg, "Insufficient Balance")
      end
    end
  end
)

Handlers.add(
  "getDataByIdError",
  Handlers.utils.hasMatchingTag("Action", "GetDataById-Error"),
  function (msg)
    local errorMap = require("json").decode(msg.Tags.Error)
    local taskKey = errorMap.userData
    local errorMsg = errorMap.errorMsg
    if PendingTasks[taskKey] ~= nil then
      local originMsg = PendingTasks[taskKey].msg
      PendingTasks[taskKey] = nil

      replyError(originMsg, "Verify data error: " .. errorMsg)
    end
  end
)

Handlers.add(
  "balanceSuccess",
  Handlers.utils.hasMatchingTag("Action", "Balance-Success"),
  function (msg)
    local dataMap = require("json").decode(msg.Data)
    local taskKey = dataMap.userData
    local balance = dataMap.data
    local originMsg = PendingTasks[taskKey].msg
    PendingTasks[taskKey].tokenBalance = balance
    PendingTasks[taskKey].tokenVerified = true

    local theTask = PendingTasks[taskKey]
    if theTask.nodeVerified and theTask.dataVerified and theTask.tokenVerified then
      if bint.__le(theTask.dataPrice, theTask.tokenBalance) then
        ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "TransferFrom", Sender = theTask.from, Recipient = ao.id, Quantity = theTask.dataPrice, UserData = taskKey}})
      else
        PendingTasks[taskKey] = nil
        replyError(originMsg, "Insufficient Balance")
      end
    end
  end
)

Handlers.add(
  "balanceError",
  Handlers.utils.hasMatchingTag("Action", "Balance-Error"),
  function (msg)
    local errorMap = require("json").decode(msg.Tags.Error)
    local taskKey = errorMap.userData
    local errorMsg = errorMap.errorMsg
    if PendingTasks[taskKey] ~= nil then
      local originMsg = PendingTasks[taskKey].msg
      PendingTasks[taskKey] = nil

      replyError(originMsg, "Verify token error: " .. errorMsg)
    end
  end
)

Handlers.add(
  "transferFromSuccess",
  Handlers.utils.hasMatchingTag("Action", "TransferFrom-Success"),
  function (msg)
    local dataMap = require("json").decode(msg.Data)
    local taskKey = dataMap.userData
    local originMsg = PendingTasks[taskKey].msg

    PendingTasks[taskKey].msg = nil
    replySuccess(originMsg, taskKey)
  end
)

Handlers.add(
  "transferFromError",
  Handlers.utils.hasMatchingTag("Action", "TransferFrom-Error"),
  function (msg)
    local errorMap = require("json").decode(msg.Tags.Error)
    local taskKey = errorMap.userData
    local errorMsg = errorMap.errorMsg
    if PendingTasks[taskKey] ~= nil then
      local originMsg = PendingTasks[taskKey].msg
      PendingTasks[taskKey] = nil

      replyError(originMsg, "transfer from error: " .. errorMsg)
    end
  end
)
    
Handlers.add(
  "getPendingTasks",
  Handlers.utils.hasMatchingTag("Action", "GetPendingTasks"),
  function (msg)
    for taskId, task in pairs(PendingTasks) do
      print(taskId .. " node:" .. tostring(task.nodeVerified) .. " data: " .. tostring(task.dataVerified) .. " token: " .. tostring(task.tokenVerified))
    end
    replySuccess(msg, PendingTasks)
  end
)

Handlers.add(
  "reportResult",
  Handlers.utils.hasMatchingTag("Action", "ReportResult"),
  function (msg)
    if msg.Tags.TaskId == nil then
      replyError(msg, "TaskId is required")
      return
    end

    if msg.Tags.NodeName == nil then
      replyError(msg, "NodeName is required")
      return
    end

    if msg.Data == nil then
      replyError(msg, "Data is required")
      return
    end

    local taskKey = getExistingTaskKey(msg)
    local pendingTask = PendingTasks[taskKey]
    if pendingTask == nil then
      replyError(msg, "PendingTask " .. taskKey .. " not exist")
      return
    end

    local requiredFrom = pendingTask.computeNodeMap[msg.Tags.NodeName]
    if requiredFrom == nil then
      replyError(msg, "NodeName[" .. msg.Tags.NodeName .. "] not in ComputeNodes")
      return
    elseif requiredFrom ~= msg.From then
      replyError(msg, msg.Tags.NodeName .. " should reported by " .. requiredFrom)
      return
    end
    PendingTasks[taskKey].result = PendingTasks[taskKey].result or {}
    PendingTasks[taskKey].result[msg.Tags.NodeName] = msg.Data
    PendingTasks[taskKey].computeNodeMap[msg.Tags.NodeName] = nil
    if count(PendingTasks[taskKey].computeNodeMap) == 0 then
      local theTask = PendingTasks[taskKey]
      ao.send({Target = TOKEN_PROCESS_ID, Tags = {Action = "Transfer", Recipient = theTask.dataProvider, Quantity = theTask.dataPrice}})
      CompletedTasks[taskKey] = PendingTasks[taskKey]
      CompletedTasks[taskKey].computeNodeMap = nil
      PendingTasks[taskKey] = nil
    end
    replySuccess(msg, taskKey)
  end
)

Handlers.add(
  "getCompletedTaskById",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTaskById"),
  function (msg)
    if msg.Tags.TaskId == nil then
      replyError(msg, "TaskId is required")
      return
    end

    local taskKey = getExistingTaskKey(msg)
    local task = CompletedTasks[taskKey]
    if task == nil then
      replyError(msg, "CompletedTask " .. taskKey .. " not exist")
      return
    end

    replySuccess(msg, task)
  end
)

Handlers.add(
  "getCompletedTasks",
  Handlers.utils.hasMatchingTag("Action", "GetCompletedTasks"),
  function (msg)
    replySuccess(msg, CompletedTasks)
  end
)

Handlers.add(
  "getAllTasks",
  Handlers.utils.hasMatchingTag("Action", "GetAllTasks"),
  function (msg)
    local allTasks = {}
    allTasks.pendingTasks = getTaskList(PendingTasks)
    allTasks.completedTasks = getTaskList(CompletedTasks)

    replySuccess(msg, allTasks)
  end
)
Handlers.add(
  "deleteCompletedTaskById",
  Handlers.utils.hasMatchingTag("Action", "DeleteCompletedTaskById"),
  function (msg)
    if msg.Tags.TaskId == nil then
      replyError(msg, "TaskId is required")
      return
    end

    local taskKey = getExistingTaskKey(msg)
    local task = CompletedTasks[taskKey]
    if task == nil then
      replyError(msg, "CompletedTask " .. taskKey .. " not exist")
      return
    end
    CompletedTasks[taskKey] = nil

    replySuccess(msg, "deleted")
  end
)

