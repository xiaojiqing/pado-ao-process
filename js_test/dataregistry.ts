import {message, result} from "@permaweb/aoconnect"
import {DATA_PROCESS} from "./constants"
import {getSigner, getTag} from "./utils"

export async function testRegistry(signer: any) {
    let action = "Register"
    let dataTag = Date() 
    let price = JSON.stringify({"price": 1, "symbol": "AOCRED"})
    let encSks = "enc private key"
    let nonce = "a nonce"
    let encMsg = "ciphertext"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataTag", "value": dataTag},
            {"name": "Price", "value": price},
            {"name": "Nonce", "value": nonce},
            {"name": "EncMsg", "value": encMsg},
        ],
        "data": encSks
    });
    
    let Result = await result({
        "process": DATA_PROCESS,
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
    // console.log(Messages[0].Tags)

    return Messages[0].Data
}

async function testGetDataById(dataId: string, signer: any) {
    let action = "GetDataById"
    
    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataId", "value": dataId},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
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

export async function testAllData(signer: any) {
    let action = "AllData"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
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

export async function testDelete(dataId: string, signer: any) {
    let action = "Delete"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataId", "value": dataId},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
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
export async function main() {
    const signer = await getSigner("wallet.json")

    let dataId = await testRegistry(signer)
    console.log("dataId: ", dataId)

    let res = await testGetDataById(dataId, signer)
    console.log(`get data by id: ${res}`)

    res = await testAllData(signer)
    console.log(`all data: ${res}`)

    res = await testDelete(dataId, signer)
    console.log(`delete: ${res}`)
}
// main()
