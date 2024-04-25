Nodes = Nodes or {}

function getNodeKey(msg)
  return msg.Name
end

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    if msg.Name == nil then
      Handlers.utils.reply("Name is required")(msg)
      return
    end

    if msg.Data == nil then
      Handlers.utils.reply("Data is required")(msg)
      return
    end

    if msg.Desc == nil then
      Handlers.utils.reply("Desc is required")(msg)
      return
    end

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] ~= nil then
      Handlers.utils.reply("already register " .. msg.Name)(msg)
      return
    end
    Nodes[nodeKey] = {}
    Nodes[nodeKey].name = msg.Name
    Nodes[nodeKey].publickey = msg.Data
    Nodes[nodeKey].desc = msg.Desc
    Nodes[nodeKey].from = msg.From
    Handlers.utils.reply("register " .. msg.Name .. " by " .. msg.From)(msg)
  end
)

Handlers.add(
  "update",
  Handlers.utils.hasMatchingTag("Action", "Update"),
  function (msg)
    if msg.Name == nil then
      Handlers.utils.reply("Name is required")(msg)
      return
    end

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] == nil then
      Handlers.utils.reply("record " .. msg.Name .. " not exist")(msg)
      return
    end

    if Nodes[nodeKey].from ~= msg.From then
      Handlers.utils.reply("you are forbidden to update")(msg)
      return
    end

    if msg.Data ~= nil then
      Nodes[nodeKey].publickey = msg.Data
    end

    if msg.Desc ~= nil then
      Nodes[nodeKey].desc = msg.Desc
    end
    Handlers.utils.reply("update " .. msg.Name .. " by " .. msg.From)(msg)
  end
)

Handlers.add(
  "delete",
  Handlers.utils.hasMatchingTag("Action", "Delete"),
  function (msg)
    if msg.Name == nil then
      Handlers.utils.reply("Name is required")(msg)
      return
    end

    local nodeKey = getNodeKey(msg)

    if Nodes[nodeKey] == nil then
      Handlers.utils.reply("record " .. msg.Name .. " not exist")(msg)
      return
    end

    if Nodes[nodeKey].from ~= msg.From then
      Handlers.utils.reply("you are forbidden to delete")(msg)
      return
    end
    Nodes[nodeKey] = nil

    Handlers.utils.reply("delete " .. msg.Name .. " by " .. msg.From)(msg)
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
    Send({ Target = msg.From, Data = require('json').encode(nodes) }) 
  end
)

Handlers.add(
  "getNodeByName",
  Handlers.utils.hasMatchingTag("Action", "GetNodeByName"),
  function (msg)
    if msg.Name == nil then
      Handlers.utils.reply("Name is required")(msg)
      return
    end

    local nodeKey = getNodeKey(msg)
    if Nodes[nodeKey] == nil then
      Handlers.utils.reply("record " .. msg.Name .. " not exist")(msg)
      return
    end

    local node = Nodes[nodeKey]
    local encodedNode = require("json").encode(node)
    Handlers.utils.reply(encodedNode)(msg)
  end
)
