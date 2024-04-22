Nodes = Nodes or {}

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    if msg.Name == nil then
      Handlers.utils.reply("Name is required")(msg)
      return
    end

    if msg.Publickey == nil then
      Handlers.utils.reply("Publickey is required")(msg)
      return
    end

    if msg.Desc == nil then
      Handlers.utils.reply("Desc is required")(msg)
      return
    end

    if Nodes[msg.Name] ~= nil then
      Handlers.utils.reply("already registered")(msg)
      return
    end
    Nodes[msg.Name] = {}
    Nodes[msg.Name].name = msg.Name
    Nodes[msg.Name].publickey = msg.Publickey
    Nodes[msg.Name].desc = msg.Desc
    Nodes[msg.Name].from = msg.From
    Handlers.utils.reply("registered")(msg)
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

    if Nodes[msg.Name] == nil then
      Handlers.utils.reply("record not exist")(msg)
      return
    end

    if Nodes[msg.Name].from ~= msg.From then
      Handlers.utils.reply("you are forbidden to update")(msg)
      return
    end

    if msg.Publickey ~= nil then
      Nodes[msg.Name].publickey = msg.Publickey
    end

    if msg.Desc ~= nil then
      Nodes[msg.Name].desc = msg.Desc
    end
    Handlers.utils.reply("updated")(msg)
  end
)

Handlers.add('nodes', Handlers.utils.hasMatchingTag('Action', 'Nodes'),
  function(msg) Send({ Target = msg.From, Data = require('json').encode(Nodes) }) end)
