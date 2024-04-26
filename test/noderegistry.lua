NodeProcess = ""

function setNodeProcess(processId)
  NodeProcess = processId
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

function testRegistry()
  addHandler("register", "Register")

  local action = "Register"
  local name = "aos"
  local publicKey = "Public Key"
  local desc = "Description"

  ao.send({Target = NodeProcess,  Action =  action})
  ao.send({Target = NodeProcess,  Action =  action, Name = name})
  ao.send({Target = NodeProcess,  Action =  action, Name = name, Data = publicKey})
  ao.send({Target = NodeProcess,  Action =  action, Name = name, Data = publicKey, Desc = desc})
  ao.send({Target = NodeProcess,  Action =  action, Name = name, Data = publicKey, Desc = desc})
end

function testUpdate()
  addHandler("update", "Update")

  local action = "update"
  local name = "aos"
  local name2 = "aos2"
  local publicKey = "Public Key"
  local desc = "Description"

  ao.send({Target = NodeProcess,  Action =  action})
  ao.send({Target = NodeProcess,  Action =  action, Name = name})
  ao.send({Target = NodeProcess,  Action =  action, Name = name2})
  ao.send({Target = NodeProcess,  Action =  action, Name = name, Data = publicKey})
  ao.send({Target = NodeProcess,  Action =  action, Name = name, Data = publicKey, Desc = desc})
  ao.send({Target = NodeProcess,  Action =  action, Name = name, Data = publicKey, Desc = desc})
end

function testDelete()
  addHandler("delete", "Delete")

  local action = "Delete"
  local name = "aos"
  local name2 = "aos2"
  local publicKey = "Public Key"
  local desc = "Description"

  ao.send({Target = NodeProcess,  Action =  action})
  ao.send({Target = NodeProcess,  Action =  action, Name = name})
  ao.send({Target = NodeProcess,  Action =  action, Name = name})
  ao.send({Target = NodeProcess,  Action =  action, Name = name2})
end

function testNodes()
  addHandler("nodes", "Nodes")

  local action = "Nodes"
  ao.send({Target = NodeProcess, Action = action})
end

function testGetNodeByName()
  addHandler("getNodeByName", "GetNodeByName")
  
  local action = "GetNodeByName"
  local name = "aos"
  local name = "aos2"

  ao.send({Target = NodeProcess,  Action =  action})
  ao.send({Target = NodeProcess,  Action =  action, Name = name})
  ao.send({Target = NodeProcess,  Action =  action, Name = name})
  ao.send({Target = NodeProcess,  Action =  action, Name = name2})
end

function testAll()
  testRegistry()
  testUpdate()
  testDelete()
  testNodes()
  testGetNodeByName()
end
