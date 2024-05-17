# pado-ao-process
PADO AO Process is processes on AO. It mainly manage nodes, data and verifiable confidential computation tasks and results. It also handles computation cost. It includes `Node Registry Process`, `Data Registry Process` and `Task Management Process`.

## Node Registry Process
Node Registry Process manages the public keys of computation nodes. It provides the functionality of add, update, delete and query. These operations are allowed only when the caller is in the white list.
A node has the following attributes:
- **name**: the name of the node
- **index**: the index of the node, starting from 1, allocated when registered
- **publicKey**: the public key of the node
- **desc**: description of the node
- **from**: the process which register the node

### Add to white list
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "AddWhiteList", Address = <Address>})
  ```
### Query white list
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "GetWhiteList"})
  ```

### Remove from white list
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "RemoveWhiteList", Address = <Address>})
  ```

###  Register a node:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Register", Name = <Name>, Data = <Public Key>, Desc = <Desc>})
  ```

###  Update a node:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Update", Name = <Name>, Data = <Public Key>, Desc = <Desc>})
  ```

###  Delete a node:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Delete", Name = <Name>})
  ```  

###  Get all nodes:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Nodes"})
  ```
  
###  Get a node by its name:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "GetNodeByName", Name = <Name>})
  ```     

## Data Registry Process
Data Registry Process manages data uploaded by data provider. 

The data has the following attributes:
- **id**: the identify of the data
- **dataTag**: the tag of the data
- **price**: the price of the data
- **data**: the content of the data
- **from**: the process which upload the data

###  Upload data:
  ```bash
  aos> Send({Target = <Data Manager ID>, Action = "Register", DataTag = <Data Tag>, Price = <Price>, Data = <EncSks>, Nonce = <Nonce>, EncMsg = <EncMsg>})
  ``` 

###  Get All Data
  ```bash
  aos> Send({Target = <Data Manager ID>, Action = "AllData"})
  ```

###  Get Data By Id
  ```bash
  aos> Send({Target = <Data Manager ID>, Action = "GetDataById", DataId = <Data ID>})
  ```

###  Delete Data
  ```bash
  aos> Send({Target = >Data Manager ID>, Action = "Delete", DataId = <Data ID>})
  ```

## Task Management Process
A task means the process that data consumer submits a request for purchase data, compute nodes operate on the data and provide their computation results, finally data consumer decrypt the data basing on the computation results.

The task has the following attributes:
 - **id**: the identity of the task
 - **type**: the task type of the task
 - **inputData**: the params of the task
 - **computeLimit**: the compute limit of the task
 - **memoryLimit**: the memory limit of the task
 - **computeNodes**: the nodes which participant in computing

### Get computation price
   ```bash
   aos> Send({Target = <Task Manager ID>, Action = "ComputationPrice"})
   ```
###  Submit a task:
   ```bash 
  aos> Send({Target = <Task Manager ID>, Action = "Submit", TaskType = <TaskType>, Data = <InputData>, ComputeLimit = <ComputeLimit>, MemoryLimit = <MemoryLimit>, ComputeNodes = <ComputeNodes>})
  ```
  
###  Report result on a task:
  ```bash
  aos> Send({Target = <Task Manger ID>, Action = "ReportResult", TaskId = <TaskID>, NodeName = <NodeName>})
  ```
  
###  Get Pending Tasks
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetPendingTasks"})
  ```
  
###  Get Completed Tasks
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetCompletedTasks"})
  ```
  
###  Get Completed Task By Id
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetCompletedById", TaskId = <TaskId>})
  ```
  
###  Get All Tasks
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetAllTasks"})
  ``` 
### Query Allowances
  ```bash
  aos> Send({Target = <TaskManager ID>, Action = "Allowances"})
  ```
### Withdraw
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "Withdraw", Recipient = <Recipient>, Quantity = <Quantity>})
  ```
### Manage Token
  For now, Pado AO uses AOCRED to incentive data providers and computation nodes. Data consumer should transfer AOCRED tokens to the `Task Management Process` before submiting tasks. In `Task Management Process`, It maintains `FreeAllowances` and `LockedAllowances` to track the tokens of data consumers. It mainly consist of the following steps.
- **Preparation**: Data consumers transfer AOCRED tokens to this process, which are kept in FreeAllowances.
- **Submit Tasks**: If a task is submitted successfully, AOCRED tokens will be moved from FreeAllowances to LockedAllowances.
- **Report Results**: If computation nodes finish computing tasks submitted, they will report result. AOCRED tokens will be transfered from this process to computation nodes and data providers. LockedAllowances will be decreased.
- **Withdraw**: If some tokens is left in FreeAllowances, data consumers can withdraw.
