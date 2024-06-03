NODE_REGISTRY_MANAGER = NODE_REGISTRY_MANAGER or ao.env.Process.Owner 
Nodes = Nodes or {}
WhiteList = WhiteList or {}
NodeIndex = NodeIndex or 0

function getNodeKey(msg)
  return msg.Tags.Name
end

Handlers.add(
  "addWhiteList",
  Handlers.utils.hasMatchingTag("Action", "AddWhiteList"),
  function (msg)
    if msg.Tags.Address == nil then
      replyError(msg, "Address is required")
      return
    end

    if msg.From ~= NODE_REGISTRY_MANAGER then
      replyError(msg, "Forbitten to operate white list")
      return
    end

    local address = msg.Tags.Address
    local index = indexOf(WhiteList, address)
    if index ~= nil then
      replyError(msg, "Already added")
      return
    end

    table.insert(WhiteList, address)
    replySuccess(msg, "Added successfully")
  end
)

Handlers.add(
  "getWhiteList",
  Handlers.utils.hasMatchingTag("Action", "GetWhiteList"),
  function (msg)
    replySuccess(msg, WhiteList)
  end
)

Handlers.add(
  "removeWhiteList",
  Handlers.utils.hasMatchingTag("Action", "RemoveWhiteList"),
  function (msg)
    if msg.Tags.Address == nil then
      replyError(msg, "Address is required")
      return
    end

    if msg.From ~= NODE_REGISTRY_MANAGER then
      replyError(msg, "Forbitten to operate white list")
      return
    end

    local address = msg.Tags.Address
    local index = indexOf(WhiteList, address)
    if index == nil then
      replyError(msg, "Not found in white list")
      return
    end

    table.remove(WhiteList, index)
    replySuccess(msg, "remove successfully")
  end
)

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    if msg.Tags.Name == nil then
      replyError(msg, "Name is required")
      return
    end

    if msg.Data == nil then
      replyError(msg, "Data is required")
      return
    end

    if msg.Tags.Desc == nil then
      replyError(msg, "Desc is required")
      return
    end

    if indexOf(WhiteList, msg.From) == nil then
      replyError(msg, "Not allowed to register node " .. "by " .. msg.From)
      return
    end

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] ~= nil then
      replyError(msg, "already register " .. msg.Name)
      return
    end
    Nodes[nodeKey] = {}
    NodeIndex = NodeIndex + 1
    Nodes[nodeKey].index = tostring(NodeIndex)
    Nodes[nodeKey].name = msg.Tags.Name
    Nodes[nodeKey].publickey = msg.Data
    Nodes[nodeKey].desc = msg.Tags.Desc
    Nodes[nodeKey].from = msg.From
    replySuccess(msg, "register " .. msg.Tags.Name .. " by " .. msg.From)
  end
)

Handlers.add(
  "update",
  Handlers.utils.hasMatchingTag("Action", "Update"),
  function (msg)
    if msg.Tags.Name == nil then
      replyError(msg, "Name is required")
      return
    end

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] == nil then
      replyError(msg, "record " .. msg.Tags.Name .. " not exist")
      return
    end

    if Nodes[nodeKey].from ~= msg.From then
      replyError(msg, "you are forbidden to update")
      return
    end

    if msg.Tags.Desc ~= nil then
      Nodes[nodeKey].desc = msg.Tags.Desc
    end
    replySuccess(msg, "update " .. msg.Tags.Name .. " by " .. msg.From)
  end
)

Handlers.add(
  "delete",
  Handlers.utils.hasMatchingTag("Action", "Delete"),
  function (msg)
    if msg.Tags.Name == nil then
      replyError(msg, "Name is required")
      return
    end

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] == nil then
      replyError(msg, "record " .. msg.Tags.Name .. " not exist")
      return
    end

    if Nodes[nodeKey].from ~= msg.From and msg.From ~= NODE_REGISTRY_MANAGER then
      replyError(msg, "you are forbidden to delete")
      return
    end
    Nodes[nodeKey] = nil
    ao.send({Target = DATA_PROCESS_ID, Tags = {Action = "DeleteNodeNotice", Name =  msg.Tags.Name}})

    replySuccess(msg, "delete " .. msg.Tags.Name .. " by " .. msg.From)
  end
)

Handlers.add(
  'nodes',
  Handlers.utils.hasMatchingTag('Action', 'Nodes'),
  function(msg)
    local nodes = {}
    for _, node in pairs(Nodes) do
      table.insert(nodes, node)
    end
    replySuccess(msg, nodes)
  end
)

Handlers.add(
  "getNodeByName",
  Handlers.utils.hasMatchingTag("Action", "GetNodeByName"),
  function (msg)
    if msg.Tags.Name == nil then
      replyError(msg, "Name is required")
      return
    end

    local nodeKey = getNodeKey(msg)
    if Nodes[nodeKey] == nil then
      replyError(msg, "record " .. msg.Tags.Name .. " not exist")
      return
    end

    local node = Nodes[nodeKey]
    replySuccess(msg, node)
  end
)

Handlers.add(
  "getComputeNodes",
  Handlers.utils.hasMatchingTag("Action", "GetComputeNodes"),
  function (msg)
    local computeNodes = require("json").decode(msg.Tags.ComputeNodes)
    local computeNodeMap = {}
    for _, nodeName in ipairs(computeNodes) do
      if Nodes[nodeName] == nil then
        local errorMsg = "not found node: " .. nodeName
        replyError(msg, errorMsg)
        return
      end
      computeNodeMap[nodeName] = Nodes[nodeName].from
    end

    replySuccess(msg, computeNodeMap)
  end
)

Handlers.add(
  "verifyComputeNodes",
  Handlers.utils.hasMatchingTag("Action", "VerifyComputeNodes"),
  function (msg)
    if msg.Tags.ComputeNodes == nil then
      replyError(msg, "ComputeNodes is required")
      return
    end

    local computeNodes = require("json").decode(msg.Tags.ComputeNodes)
    for _, node in ipairs(computeNodes) do
      local name = node.name
      local index = node.index
      if Nodes[name] == nil then
        replyError(msg, "NodeName[" .. name .. "] not exist")
        return
      end

      if Nodes[name].index ~= index then
        replyError(msg, "the index of NodeName[" .. name .. "] is incorrect")
        return
      end
    end

    replySuccess(msg, "verification passed")
  end
)
