Nodes = Nodes or {}

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    Nodes[msg.Name] = Nodes[msg.Name] or {}
    Nodes[msg.Name].name = msg.Name
    Nodes[msg.Name].publickey = msg.Data
    Nodes[msg.Name].desc = msg.Desc
    Nodes[msg.Name].from = msg.From
    Handlers.utils.reply("registered")(msg)
  end
)

Handlers.add('nodes', Handlers.utils.hasMatchingTag('Action', 'Nodes'),
  function(msg) Send({ Target = msg.From, Data = require('json').encode(Nodes) }) end)