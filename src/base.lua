NODE_PROCESS_ID = "qmNU_H7tsChsdpcQ7ZquN0hcxdEDKZ63pofh0wtg6B0"
DATA_PROCESS_ID = "OOusKnpwI9-8DFRob95ru_lTta_46ilKLZ7QhFWLUHM"
TASK_PROCESS_ID = "ET2zTzyA7Ddvq_JJ7N5RQDex-fQjFQ6kfRV_6bg36ys"
 
function replyError(request, errmsg)
  local action = request.Action .. "-Error"
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Error = errmsg})
end

function replySuccess(request, data)
  local action = request.Action .. "-Success"
  ao.send({Target = request.From, Action = action, ["Message-Id"] = request.Id, Data = data})
end

