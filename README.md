# pado-ao-process
This is PADO Network AO Processes.

## Node Register
A node has the following attributes:
- name
  * the name of the node
- publicKey
  * the public key of the node
- desc
  * description of the node
- from
  * the process which register the node

  Register a node:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Register", Name = <Name>, Data = <Public Key>, Desc = <Desc>})
  ```

  Update a node:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Update", Name = <Name>, Data = <Public Key>, Desc = <Desc>})
  ```

  Delete a node:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Delete", Name = <Name>})
  ```  

  Get all nodes:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "Nodes"})
  ```
  
  Get a node by its name:
  ```bash
  aos> Send({Target = <Node Manager ID>, Action = "GetNodeByName", Name = <Name>})
  ```     

## Data Register
The data has the following attributes:
- id
  * the identify of the data
- dataTag
  * the tag of the data
- price
  * the price of the data
- encSks
  * the encrypted secret keys for the data  
- nonce
  * the nonce for the data
- encMsg
  * the ciphertext of the data
- from
  * the process which upload the data

  Upload data:
  ```bash
  aos> Send({Target = <Data Manager ID>, Action = "Register", DataTag = <Data Tag>, Price = <Price>, Data = <EncSks>, Nonce = <Nonce>, EncMsg = <EncMsg>})
  ``` 

  Get All Data
  ```bash
  aos> Send({Target = <Data Manager ID>, Action = "AllData"})
  ```

  Get Data By Id
  ```bash
  aos> Send({Target = <Data Manager ID>, Action = "GetDataById", DataId = <Data ID>})
  ```

  Delete Data
  ```bash
  aos> Send({Target = >Data Manager ID>, Action = "Delete", DataId = <Data ID>})
  ```

## Task Register
The task has the following attributes:
 - id
   * the identity of the task
 - type
   * the task type of the task
 - inputData
   * the params of the task
 - computeLimit
   * the compute limit of the task
 - memoryLimit
   * the memory limit of the task
 - computeNodes
   * the nodes which participant in computing
   
  Submit a task:
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "Submit", TaskType = <TaskType>, Data = <InputData>, ComputeLimit = <ComputeLimit>, MemoryLimit = <MemoryLimit>, ComputeNodes = <ComputeNodes>})
  ```
  
  Report result on a task:
  ```bash
  aos> Send({Target = <Task Manger ID>, Action = "ReportResult", TaskId = <TaskID>, NodeName = <NodeName>})
  ```
  
  Get Pending Tasks
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetPendingTasks"})
  ```
  
  Get Completed Tasks
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetCompletedTasks"})
  ```
  
  Get Completed Task By Id
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetCompletedById", TaskId = <TaskId>})
  ```
  
  Get All Tasks
  ```bash
  aos> Send({Target = <Task Manager ID>, Action = "GetAllTasks"})
  ``` 
