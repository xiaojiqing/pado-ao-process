import {message, result} from "@permaweb/aoconnect"
import {TOKEN_PROCESS, TASK_PROCESS} from "./constants"
import {getSigner, getWalletAddress} from "./utils"
import {testRegistry as registerData, testDelete as deleteData} from "./dataregistry"
import {registerAllNodes, deleteAllNodes} from "./noderegistry"

async function transferTokenToTask(quantity: string, signer: any) {
    let action = "Transfer"

    let msgId = await message({
        "process": TOKEN_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Recipient", "value": TASK_PROCESS},
            {"name": "Quantity", "value": quantity},
        ]
    });

    let res = await result({
        "process": TOKEN_PROCESS,
        "message": msgId,
    });
    console.log("transfer result: ", res)
}
async function testSubmit(dataId: string, nodes: string[], signer: any) {
    let action = "Submit"
    let taskType = "task type"
    let inputData = "input data"
    let computeLimit = "200"
    let memoryLimit = "300"
    let encodedNodes = JSON.stringify(nodes)

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": signer,
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

    let {Messages} = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    
    // console.log(Messages)
    const address = await getWalletAddress()
    console.log(address)
    for (const msg of Messages) {
        if (msg.Target === address) {
            return msg.Data
        }
    }
    return null;
}

async function testGetTasks(action: string, signer: any) {
    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
        ],
    });

    let {Messages} = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    return Messages[0].Data
}

async function testGetPendingTasks(signer: any) {
    let pendingTasks =  await testGetTasks("GetPendingTasks", signer)
    console.log(`pendingTasks: ${pendingTasks}`)
}

async function testGetCompletedTasks(signer: any) {
    let completedTasks =  await testGetTasks("GetCompletedTasks", signer)
    console.log(`completedTasks: ${completedTasks}`)
}

async function testGetAllTasks(signer: any) {
    let allTasks =  await testGetTasks("GetAllTasks", signer)
    console.log(`allTasks: ${allTasks}`)
}
async function testDeleteCompletedTask(taskId: string, signer:any) {
    let action = "DeleteCompletedTaskById"

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "TaskId", "value": taskId},
        ],
    });

    let {Messages} = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    return Messages[0].Data
}
async function testReportResult(node:string, taskId:string, signer:any) {
    let action = "ReportResult"
    let computeResult = "compute result"

    let msgId = await message({
        "process": TASK_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "TaskId", "value": taskId},
            {"name": "NodeName", "value": node},
        ],
        "data": computeResult
    });

    let Messages = await result({
        "process": TASK_PROCESS,
        "message": msgId,
    });
    if (!Messages.Messages[0].Data) {
        for (let msg of Messages.Messages) {
            console.log(msg.Tags)
        }
    }
    return Messages.Messages[0].Data
}
async function testReportAllResult(nodes: string[], taskId: string, signer: any) {
    for (const node of nodes) {
        let res = await testReportResult(node, taskId, signer)
        console.log(`${node} result: ${res}`)
    }
}

function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms))
}

async function main() {
    const signer = await getSigner()
    const nodes = ["js_aos1", "js_aos2", "js_aos3"]

    await registerAllNodes(nodes, signer);

    let dataId = await registerData(signer)

    await transferTokenToTask("50", signer)

    await sleep(2000)

    let taskId = await testSubmit(dataId, nodes, signer)
    console.log(`task id: ${taskId}`)

    let tasks = await testGetPendingTasks(signer)
    console.log(`tasks ${tasks}`)

    await sleep(3000)

    await testReportAllResult(nodes, taskId, signer)
    await testGetCompletedTasks(signer)
    await testGetAllTasks(signer)

    await testDeleteCompletedTask(taskId, signer);
    await deleteData(dataId, signer);
    await deleteAllNodes(nodes, signer);
    console.log(new Date())
}
main()
