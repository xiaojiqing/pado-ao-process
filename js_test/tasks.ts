import {message, result} from "@permaweb/aoconnect"
import {TOKEN_PROCESS, TASK_PROCESS} from "./constants"
import {Wallet, DataProviderWallet, ComputationProviderWallet, ResultReceiverWallet, getDataProviderWallet, getComputationProviderWallet, getResultReceiverWallet, getTag} from "./utils"
import {testRegistry as registerData, testAllData, testDelete as deleteData} from "./dataregistry"
import {registerAllNodes, testGetAllNodes, deleteAllNodes, testAddWhiteList, testGetWhiteList, testRemoveWhiteList} from "./noderegistry"

interface ClearInfo {
    whiteList: boolean,
    node: boolean,
    data: boolean,
}
async function testComputationPrice(resultReceiverWallet: ResultReceiverWallet) {
    let action = "ComputationPrice"

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": resultReceiverWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
        ]
    });

    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    console.log("computation price: ", Messages[0].Data)
    return Messages[0].Data
}
async function transferTokenToTask(quantity: string, resultReceiverWallet: ResultReceiverWallet) {
    let action = "Transfer"

    let msgId = await message({
        "process": TOKEN_PROCESS,
        "signer": resultReceiverWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Recipient", "value": TASK_PROCESS},
            {"name": "Quantity", "value": quantity},
        ]
    });

    let Result = await result({
        "process": TOKEN_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    console.log("transfer result: ", Messages[0].Data)
}
async function testSubmit(dataId: string, nodes: string[], resultReceiverWallet: ResultReceiverWallet) {
    let action = "Submit"
    let taskType = "task type"
    let inputData = Date() 
    let computeLimit = "200"
    let memoryLimit = "300"
    let encodedNodes = JSON.stringify(nodes)

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": resultReceiverWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "TaskType", "value": taskType},
            {"name": "ComputeLimit", "value": computeLimit},
            {"name": "MemoryLimit", "value": memoryLimit},
            {"name": "ComputeNodes", "value": encodedNodes},
            {"name": "DataId", "value": dataId},
        ],
        "data": inputData
    });

    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    for (const msg of Messages) {
        if (msg.Target === resultReceiverWallet.address) {
            return msg.Data
        }
    }
    return null;
}

async function testGetTasks(action: string, wallet: Wallet) {
    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": wallet.signer,
        "tags": [
            {"name": "Action", "value": action},
        ],
    });

    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    return Messages[0].Data
}

async function testGetPendingTasks(computeProviderWallet: ComputationProviderWallet) {
    let pendingTasks =  await testGetTasks("GetPendingTasks", computeProviderWallet)
    console.log(`pendingTasks: ${pendingTasks}`)
    return pendingTasks
}

async function testGetCompletedTasks(resultReceiverWallet: ResultReceiverWallet) {
    let completedTasks =  await testGetTasks("GetCompletedTasks", resultReceiverWallet)
    console.log(`completedTasks: ${completedTasks}`)
    return completedTasks
}

async function testGetAllTasks(resultReceiverWallet: ResultReceiverWallet) {
    let allTasks =  await testGetTasks("GetAllTasks", resultReceiverWallet)
    console.log(`allTasks: ${allTasks}`)
    return allTasks
}
async function testGetCompletedTaskById(taskId: string, resultReceiverWallet: ResultReceiverWallet) {
    let action = "GetCompletedTaskById"
    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": resultReceiverWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "TaskId", "value": taskId},
        ]
    })

    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    })
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    return Messages[0].Data
}

async function getExpectedMessage(Messages: any[], address: string) {
    console.log("address ", address)
    // console.log("messages ", Messages)
    let targets = []
    for (let msg of Messages) {
        targets.push(msg.Target)
        if (msg.Target === address) {
            return msg;
        }
    }
    console.log(targets)
    return null
}

async function testReportResult(node:string, taskId:string, computeWallet: ComputationProviderWallet) {
    let action = "ReportResult"
    let computeResult = "compute result"

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": computeWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "TaskId", "value": taskId},
            {"name": "NodeName", "value": node},
        ],
        "data": computeResult
    });

    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    let Message = await getExpectedMessage(Messages, computeWallet.address)
    if (Message == null) {
        for (let msg of Messages) {
            console.log(msg)
            console.log(msg.Tags)
        }
    }
    if (getTag(Message, "Error")) {
        throw getTag(Message, "Error")
    }
    return Message.Data
}
async function testReportAllResult(taskId: string, computeWallet: ComputationProviderWallet) {
    let pendingTasks = await testGetPendingTasks(computeWallet)
    let pendingTasks2 = JSON.parse(pendingTasks)

    for (let pendingTask of pendingTasks2) {
        if (pendingTask.id === taskId) {
            for (const node in pendingTask.computeNodeMap) {
                let res = await testReportResult(node, taskId, computeWallet)
                console.log(`${node} result: ${res}`)
            }
        }
    }
}
async function testBalance(address: string, wallet: Wallet) {
    let action = "Balance"

    let msgId = await message({
        "process": TOKEN_PROCESS,
        "signer": wallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Recipient", "value": address},
        ]
    });

    let Result = await result({
        "process": TOKEN_PROCESS,
        "message": msgId,
    });

    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    console.log("Balance: ", Messages[0].Data)
    return Messages[0].Data
}

async function testWalletBalance(wallet: Wallet) {
    let balance = await testBalance(wallet.address, wallet)
    console.log(wallet.kind, balance)
}

async function testAllowance(resultReceiverWallet: ResultReceiverWallet) {
    let action = "Allowance"

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": resultReceiverWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
        ]
    });
    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    // console.log(Messages)
    console.log("allowance: ", Messages[0].Data)
    return Messages[0].Data
}
async function testWithdraw(quantity: string, resultWallet: ResultReceiverWallet) {
    let action = "Withdraw"

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": resultWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Quantity", "value": quantity},
        ]
    });
    let Result = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    })
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    let Message = await getExpectedMessage(Messages, resultWallet.address)
    console.log("withdraw: ", Message.Data)
    return Message.Data
}

async function withdraw(resultWallet: ResultReceiverWallet) {
    let address = resultWallet.address
    await testBalance(address, resultWallet)
    await testBalance(TASK_PROCESS,resultWallet)

    let allowance = await testAllowance(resultWallet)
    let freeAllowance = JSON.parse(allowance).free
    if (freeAllowance !== "0") {
        await testWithdraw(freeAllowance, resultWallet)
        await testBalance(address, resultWallet)
        await testBalance(TASK_PROCESS, resultWallet)
    }
}

async function clear(clearInfo: ClearInfo, computeWallet: ComputationProviderWallet, dataWallet: DataProviderWallet) {
    if (clearInfo.whiteList) {
        let validAddresses = await testGetWhiteList(computeWallet)
        console.log(typeof validAddresses, validAddresses)
        let whiteList = JSON.parse(validAddresses)
        for (const address of whiteList) {
            await testRemoveWhiteList(address, computeWallet)
        }
    }

    if (clearInfo.node) {
        let registeredNodes = await testGetAllNodes(computeWallet)
        console.log("registeredNodes", typeof registeredNodes, registeredNodes)
        let nodes = JSON.parse(registeredNodes) 
        let nodeNames = []
        for (const node of nodes) {
            nodeNames.push(node.name)
        }
        await deleteAllNodes(nodeNames, computeWallet);
    }

    if (clearInfo.data) {
        let registeredData = await testAllData(dataWallet)
        console.log("registeredData", typeof registeredData, registeredData)
        let allData = JSON.parse(registeredData)
        for (const data of allData) {
            await deleteData(data.id, dataWallet);
        }
    }
}

function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms))
}

async function main() {
    const dataWallet = await getDataProviderWallet()
    const computeWallet = await getComputationProviderWallet()
    const resultWallet = await getResultReceiverWallet()
    console.log(dataWallet)
    console.log(computeWallet)
    console.log(resultWallet)

    await testWalletBalance(dataWallet)
    await testWalletBalance(computeWallet)
    await testWalletBalance(resultWallet)
    await testBalance(TASK_PROCESS, resultWallet)
    await testAllowance(resultWallet)
    await testComputationPrice(resultWallet)

    const nodes = ["js_aos1", "js_aos2", "js_aos3"]
    let clearInfo = {"whiteList": true, "node": true, "data": true}
    await clear(clearInfo, computeWallet, dataWallet)

    await testAddWhiteList(computeWallet.address, computeWallet)
    await testGetWhiteList(computeWallet)
    await registerAllNodes(nodes, computeWallet);

    let dataId = await registerData(dataWallet)

    await transferTokenToTask("5", resultWallet)

    // clearInfo = {"whiteList": false, "node": true, "data": false}
    // await clear(clearInfo, signer)
    await sleep(5000)

    let taskId = await testSubmit(dataId, nodes, resultWallet)
    console.log(`task id: ${taskId}`)

    await sleep(5000)

    let pendingTasks = await testGetPendingTasks(computeWallet)
    let pendingTasks2 = JSON.parse(pendingTasks)
    let taskIds = []
    for (const theTask of pendingTasks2) {
        taskIds.push(theTask.id)
    }
    console.log("taskIds ", taskIds)

    for (const taskId of taskIds) {
        await testReportAllResult(taskId, computeWallet)
        await sleep(5000)
    }
    
    if (false) {
        await testGetCompletedTasks(resultWallet)
        await testGetAllTasks(resultWallet)
    }
    for (const taskId of taskIds) {
        await testGetCompletedTaskById(taskId, resultWallet)
    }

    await deleteData(dataId, dataWallet);
    await deleteAllNodes(nodes, computeWallet);
    await testRemoveWhiteList(computeWallet.address, computeWallet)

    if (true) {
        await withdraw(resultWallet)
    }
    await testWalletBalance(dataWallet)
    await testWalletBalance(computeWallet)
    await testWalletBalance(resultWallet)
    await testBalance(TASK_PROCESS, resultWallet)
    await testAllowance(resultWallet)

    return "finished"
}
main().then((msg) => {
    console.log("then: ", msg)
})
.catch((e) => {
    console.log("catch: ", e)
})
