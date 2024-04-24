Nodes = Nodes or {}

function get_node_key(msg)
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

    local node_key = get_node_key(msg)

    if Nodes[node_key] ~= nil then
      Handlers.utils.reply("already register " .. msg.Name)(msg)
      return
    end
    Nodes[node_key] = {}
    Nodes[node_key].name = msg.Name
    Nodes[node_key].publickey = msg.Data
    Nodes[node_key].desc = msg.Desc
    Nodes[node_key].from = msg.From
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

    local node_key = get_node_key(msg)

    if Nodes[node_key] == nil then
      Handlers.utils.reply("record " .. msg.Name .. " not exist")(msg)
      return
    end

    if Nodes[node_key].from ~= msg.From then
      Handlers.utils.reply("you are forbidden to update")(msg)
      return
    end

    if msg.Data ~= nil then
      Nodes[node_key].publickey = msg.Data
    end

    if msg.Desc ~= nil then
      Nodes[node_key].desc = msg.Desc
    end
    Handlers.utils.reply("update " .. msg.Name .. " by " .. msg.From)(msg)
  end
)

Handlers.add(
  "Delete",
  Handlers.utils.hasMatchingTag("Action", "Delete"),
  function (msg)
    if msg.Name == nil then
      Handlers.utils.reply("Name is required")(msg)
      return
    end

    local node_key = get_node_key(msg)

    if Nodes[node_key] == nil then
      Handlers.utils.reply("record " .. msg.Name .. " not exist")(msg)
      return
    end

    if Nodes[node_key].from ~= msg.From then
      Handlers.utils.reply("you are forbidden to delete")(msg)
      return
    end
    Nodes[node_key] = nil

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
