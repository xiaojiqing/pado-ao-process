TaskProcess = TaskProcess or ""
DataProcess = DataProcess or ""
TaskId = TaskId or ""
DataId = DataId or ""

function setTaskProcess(processId)
  TaskProcess = processId
end

function setDataProcess(processId)
  DataProcess = processId
end
function addSuccessHandler(name, action)
  Handlers.add(
    name,
    Handlers.utils.hasMatchingTag("Action", action),
    function (msg)
      print("=========BEGIN=============")
      print("Action: " .. msg.Action)
      print("Message-Id: " .. msg["Message-Id"])
      print("Data: " .. msg.Data)
      print("=========END===============")
      if msg.Action == "Submit-Success" then
        TaskId = msg.Data
      elseif msg.Action == "AllData-Success" then
        allData = require("json").decode(msg.Data)
        if #allData > 0 then
          DataId = allData[1].id
        end
      end
    end
  )
end

function addErrorHandler(name, action)
  Handlers.add(
    name,
    Handlers.utils.hasMatchingTag("Action", action),
    function (msg)
      print("=============BEGIN==========")
      print("Action: " .. msg.Action)
      print("Message-Id: " .. msg["Message-Id"])
      print("Error: " .. msg.Error)
      print("=============END============")
    end
  )
end

function addHandler(name, action)
  addSuccessHandler(name .. "Success", action .. "-Success")
  addErrorHandler(name .. "Error", action .. "-Error")
end

function testAllData()
  addHandler("allData", "AllData")

  local action = "AllData"
  Send({Target = DataProcess, Action = action})
end

function testSubmit()
  addHandler("submit", "Submit")

  local action = "Submit"
  local taskType = "task type"
  local inputData = "input data"
  local computeLimit = "200"
  local memoryLimit = "300"

  local computeNodes = {}
  table.insert(computeNodes, "aos")
  table.insert(computeNodes, "aos2")
  table.insert(computeNodes, "aos3")

  local encodedNodes = require("json").encode(computeNodes)

  Send({Target = TaskProcess, Action = action})
  Send({Target = TaskProcess, Action = action, TaskType = taskType})
  Send({Target = TaskProcess, Action = action, TaskType = taskType, Data = inputData})
  Send({Target = TaskProcess, Action = action, TaskType = taskType, Data = inputData, ComputeLimit = computeLimit})
  Send({Target = TaskProcess, Action = action, TaskType = taskType, Data = inputData, ComputeLimit = computeLimit, MemoryLimit = memoryLimit})
  Send({Target = TaskProcess, Action = action, TaskType = taskType, Data = inputData, ComputeLimit = computeLimit, MemoryLimit = memoryLimit, ComputeNodes = encodedNodes})
  Send({Target = TaskProcess, Action = action, TaskType = taskType, Data = inputData, ComputeLimit = computeLimit, MemoryLimit = memoryLimit, ComputeNodes = encodedNodes, DataId = DataId})
end


function testReportResult()
  addHandler("reportSult", "ReportResult")

  local action = "ReportResult"
  local taskId = TaskId
  local nodeName1 = "aos"
  local nodeName2 = "aos2"
  local nodeName3 = "aos3"
  local result = "compute result"

  Send({Target = TaskProcess, Action = action})
  Send({Target = TaskProcess, Action = action, TaskId = taskId})
  Send({Target = TaskProcess, Action = action, TaskId = taskId, Data = result})
  Send({Target = TaskProcess, Action = action, TaskId = taskId, Data = result, NodeName = nodeName1})
  Send({Target = TaskProcess, Action = action, TaskId = taskId, Data = result, NodeName = nodeName2})
  Send({Target = TaskProcess, Action = action, TaskId = taskId, Data = result, NodeName = nodeName3})
  Send({Target = TaskProcess, Action = action, TaskId = taskId, Data = result, NodeName = nodeName3})
end


function testGetPendingTasks()
  addHandler("getPendingTasks", "GetPendingTasks")

  local action = "GetPendingTasks"
  Send({Target = TaskProcess, Action = action})
end

function testGetCompletedTasks()
  addHandler("getCompletedTasks", "GetCompletedTasks")

  local action = "GetCompletedTasks"
  Send({Target = TaskProcess, Action = action})
end

function testGetCompletedTaskById()
  addHandler("getCompletedTaskById", "GetCompletedTaskById")

  local action = "GetCompletedTaskById"
  local taskId = TaskId
  local taskId2 = "some task id"
  Send({Target = TaskProcess, Action = action})
  Send({Target = TaskProcess, Action = action, TaskId = taskId})
  Send({Target = TaskProcess, Action = action, TaskId = taskId2})
end

function testGetAllTasks()
  addHandler("getAllTasks", "GetAllTasks")

  local action = "GetAllTasks"
  Send({Target = TaskProcess, Action = action})
end

function testAll()
  testSubmit()
  testGetPendingTasks()
  testReportResult()
  testGetCompletedTasks()
  testGetCompletedTaskById()
  testGetAllTasks()
end
