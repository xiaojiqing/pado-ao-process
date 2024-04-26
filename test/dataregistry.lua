DataProcess = DataProcess or ""
DataId = DataId or ""

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
      if msg.Action == "Register-Success" then
        DataId = msg.Data
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

function testRegistry()
  addHandler("register", "Register")

  local action = "Register"
  local dataTag = "data tag"
  local price = "20"
  local encSks = "enc private key"
  local nonce = " a nonce"
  local encMsg = "ciphertext"

  Send({Target = DataProcess, Action = action})
  Send({Target = DataProcess, Action = action, DataTag = dataTag})
  Send({Target = DataProcess, Action = action, DataTag = dataTag, Price = price})
  Send({Target = DataProcess, Action = action, DataTag = dataTag, Price = price, Data = encSks})
  Send({Target = DataProcess, Action = action, DataTag = dataTag, Price = price, Data = encSks, Nonce = nonce})
  Send({Target = DataProcess, Action = action, DataTag = dataTag, Price = price, Data = encSks, Nonce = nonce, EncMsg = encMsg})
end

function testGetDataById()
  addHandler("getDataById", "GetDataById")

  local action = "GetDataById"
  local dataId = DataId
  local dataId2 = "some data id"

  Send({Target = DataProcess, Action = action})
  Send({Target = DataProcess, Action = action, DataId = dataId})
  Send({Target = DataProcess, Action = action, DataId = dataId2})
end

function testAllData()
  addHandler("allData", "AllData")

  local action = "AllData"
  Send({Target = DataProcess, Action = action})
end

function testDelete()
  addHandler("delete", "Delete")

  local action = "Delete"
  local dataId = DataId
  local dataId2 = "some data id"

  Send({Target = DataProcess, Action = action})
  Send({Target = DataProcess, Action = action, DataId = dataId})
  Send({Target = DataProcess, Action = action, DataId = dataId2})
end


function testAll()
  testRegistry()
  testGetDataById()
  testAllData()
  testDelete()
end
   
