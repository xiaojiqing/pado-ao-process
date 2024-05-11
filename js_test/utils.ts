import {readFileSync} from "node:fs"
import {createDataItemSigner} from "@permaweb/aoconnect"
import Arweave from "arweave"

const getArweave = async () => {
    const arweave = Arweave.init({
        "host": "arweave.net",
        "port": 443,
        "protocol": "https",
    });
    return arweave;
}

const getWallet = async () => {
    const wallet = JSON.parse(
        readFileSync("wallet.json").toString()
    );
    return wallet;
}

export const getSigner = async () => {
    const wallet = await getWallet();
    const signer = createDataItemSigner(wallet);
    return signer
}

export const getWalletAddress = async () => {
    const wallet = await getWallet();
    const arweave = await getArweave();
    const address = arweave.wallets.getAddress(wallet);
    return address;
}

export const getTag = (Message: any, Tag: string) => {
    const Tags = Message.Tags
    for (let theTag of Tags) {
        if (theTag.name === Tag) {
            return theTag.value
        }
    }
    return null
}
