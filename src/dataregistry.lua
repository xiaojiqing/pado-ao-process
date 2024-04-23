AllData = AllData or {}

Handlers.add(
  "register",
  Handlers.utils.hasMatchingTag("Action", "Register"),
  function (msg)
    AllData[msg.Id] = AllData[msg.Id] or {}
    AllData[msg.Id].id = msg.Id
    AllData[msg.Id].dataTag = msg.DataTag
    AllData[msg.Id].price = msg.Price
    AllData[msg.Id].encSks = msg.Data
    AllData[msg.Id].nonce = msg.Nonce
    AllData[msg.Id].encMsg = msg.EncMsg
    AllData[msg.Id].from = msg.From
    Handlers.utils.reply("registered")(msg)
  end
)

Handlers.add('allData', Handlers.utils.hasMatchingTag('Action', 'AllData'),
  function(msg) Send({ Target = msg.From, Data = require('json').encode(AllData) }) end)