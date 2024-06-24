import {message, result} from "@permaweb/aoconnect"
import {DATA_PROCESS} from "./constants"
import {getDataProviderWallet, DataProviderWallet, getMessage} from "./utils"

export type DataStatus = "Valid" | "Invalid" | "All"

export async function testRegistry(nodes: string[], indices: number[], dataProviderWallet: DataProviderWallet, priceSymbol: string) {
    let action = "Register"
    let dataTag = Date() 
    let price = JSON.stringify({"price": 1, "symbol": priceSymbol})
    let data = JSON.stringify({"policy": {"t": 2, "n": 3, "indices": indices, "names": nodes}})

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataTag", "value": dataTag},
            {"name": "Price", "value": price},
        ],
        "data": data
    });
    
    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    let Message = await getMessage(Result, msgId)
    return Message.Data
}

async function testGetDataById(dataId: string, dataProviderWallet: DataProviderWallet) {
    let action = "GetDataById"
    
    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataId", "value": dataId},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    let Message = await getMessage(Result, msgId)
    return Message.Data
}

export async function testAllData(dataStatus: DataStatus, dataProviderWallet: DataProviderWallet) {
    let action = "AllData"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataStatus", "value": dataStatus},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    let Message = await getMessage(Result, msgId)
    return Message.Data
}

export async function testDelete(dataId: string, dataProviderWallet: DataProviderWallet) {
    let action = "Delete"

    let msgId = await message({
        "process": DATA_PROCESS,
        "signer": dataProviderWallet.signer,
        "tags": [
            {"name": "Action", "value": action},
            {"name": "DataId", "value": dataId},
        ],
    });

    let Result = await result({
        "process": DATA_PROCESS,
        "message": msgId,
    });
    let Message = await getMessage(Result, msgId)
    return Message.Data
}
export async function main() {
    let dataProviderWallet = await getDataProviderWallet();
    let nodes = ["js_aos1", "js_aos2", "js_aos3"]
    let indices = [1, 2, 3]

    let dataId = await testRegistry(nodes, indices, dataProviderWallet, "AOCRED")
    console.log("dataId: ", dataId)

    let res = await testGetDataById(dataId, dataProviderWallet)
    console.log(`get data by id: ${res}`)

    res = await testAllData("All", dataProviderWallet)
    console.log(`all data: ${res}`)

    res = await testDelete(dataId, dataProviderWallet)
    console.log(`delete: ${res}`)
}
// main()
