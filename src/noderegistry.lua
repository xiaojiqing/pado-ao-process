Nodes = Nodes or {}
function getNodeKey(msg)
  return msg.Tags.Name
end

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

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] ~= nil then
      replyError(msg, "already register " .. msg.Name)
      return
    end
    Nodes[nodeKey] = {}
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

    if msg.Data ~= nil then
      Nodes[nodeKey].publickey = msg.Data
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

    if Nodes[nodeKey].from ~= msg.From then
      replyError(msg, "you are forbidden to delete")
      return
    end
    Nodes[nodeKey] = nil

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
    local encoded_nodes = require('json').encode(nodes)
    replySuccess(msg, encoded_nodes)
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
    local encodedNode = require("json").encode(node)
    replySuccess(msg, encodedNode)
  end
)
