import {message, result} from "@permaweb/aoconnect"
import {NODE_PROCESS} from "./constants"
import {getSigner, getTag} from "./utils"

export async function testAddWhiteList(address: string, signer: any) {
    let action = "AddWhiteList"
    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Address", "value": address},
        ]
    })

    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
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

export async function testGetWhiteList(signer: any) {
    let action = "GetWhiteList"
    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
        ],
    })

    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
    })
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    console.log("white list: ", Messages[0].Data)
    return Messages[0].Data
}

export async function testRemoveWhiteList(address: string, signer: any) {
    let action = "RemoveWhiteList"
    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Address", "value": address},
        ]
    })
    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
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
async function testRegistry(name: string, signer: any) {
    let action = "Register"
    let publicKey = "public key"
    let desc = Date() 

    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags" : [
            {"name": "Action", "value": action},
            {"name": "Name", "value": name},
            {"name": "Desc", "value": desc},
        ],
        "data": publicKey
    });

    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    // console.log("register res: ", Messages);
    return Messages[0].Data
}
export async function testGetAllNodes(signer: any) {
    let action = "Nodes"
    
    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
        ]
    });
    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
    });
    if (Result.Error) {
        console.log(Result.Error)
    }
    let Messages = Result.Messages
    if (getTag(Messages[0], "Error")) {
        throw getTag(Messages[0], "Error")
    }
    // console.log("all process: ", Messages)
    return Messages[0].Data
}

async function testGetNodeByName(name: string, signer: any) {
    let action = "GetNodeByName"

    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Name", "value": name},
        ]
    });
    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
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
async function testDelete(name: string, signer: any) {
    let action = "Delete"

    let msgId = await message({
        "process": NODE_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "Name", "value": name},
        ],
    });
    let Result = await result({
        "message": msgId,
        "process": NODE_PROCESS,
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

export async function registerAllNodes(names: string[], signer: any) {
    for (let name of names) {
        let aos = await testRegistry(name, signer);
        console.log(`register ${name} result: ${aos}`)
    }
}

async function getAllNodesByName(names: string[], signer: any) {
    for (let name of names) {
        let res = await testGetNodeByName(name, signer)
        console.log(`get node by name ${name} result: ${res}`)
    }
}

export async function deleteAllNodes(names: string[], signer: any) {
    for (let name of names) {
        let res = await testDelete(name, signer);
        console.log(`delete ${name} result: ${res}`)
    }
}

export async function main() {
    let signer = await getSigner();

    let nodes = ["js_aos", "js_aos2", "js_aos3"];
    await registerAllNodes(nodes, signer)

    let allProcess = await testGetAllNodes(signer);
    console.log("allProcess: ", allProcess)

    await getAllNodesByName(nodes, signer)

    await deleteAllNodes(nodes, signer)
}

// main()
