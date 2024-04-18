Nodes = Nodes or {}

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    Nodes[msg.Publickey] = Nodes[msg.Publickey] or {}
    Nodes[msg.Publickey].name = msg.Name
    Nodes[msg.Publickey].publickey = msg.Publickey
    Nodes[msg.Publickey].desc = msg.Desc
    Handlers.utils.reply("registered")(msg)
  end
)

Handlers.add('nodes', Handlers.utils.hasMatchingTag('Action', 'Nodes'),
  function(msg) Send({ Target = msg.From, Data = require('json').encode(Nodes) }) end)