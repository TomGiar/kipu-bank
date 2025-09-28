# KipuBank Smart Contract

## Descripción

KipuBank es un smart contract de bóveda bancaria construido en Solidity que permite a los usuarios depositar y retirar ETH de manera segura. El contrato implementa medidas de seguridad robustas, límites configurables y un sistema de eventos para el seguimiento de transacciones.

### Características Principales

- **Depósitos seguros**: Los usuarios pueden depositar ETH en su bóveda personal
- **Retiros controlados**: Sistema de retiros con límites por transacción para mayor seguridad
- **Límites configurables**: Capacidad máxima del banco y umbral de retiro establecidos al despliegue
- **Prevención de reentrancy**: Implementa el patrón checks-effects-interactions
- **Sistema de eventos**: Seguimiento completo de operaciones mediante eventos
- **Estadísticas del banco**: Información completa sobre el estado del contrato

## Funcionalidades

### Variables Principales

- `s_withdrawalThreshold`: Umbral máximo que un usuario puede retirar por transacción
- `s_bankCap`: Límite máximo global de depósitos que puede manejar el banco
- `s_totalDeposits`: Total de ETH depositado actualmente
- `s_depositCount`: Contador de operaciones de depósito
- `s_withdrawalCount`: Contador de operaciones de retiro
- `balances`: Mapeo que almacena el saldo de cada usuario

### Funciones Públicas

#### `deposit()` (payable)
Permite a los usuarios depositar ETH en su bóveda personal.
- **Validaciones**: Monto > 0, no exceder capacidad del banco
- **Emite**: `KipuBank_DepositMade`

#### `withdraw(uint256 _amount)`
Permite retirar ETH de la bóveda personal.
- **Parámetros**: `_amount` - cantidad a retirar en wei
- **Validaciones**: Monto > 0, balance suficiente, no exceder umbral de retiro
- **Emite**: `KipuBank_WithdrawalMade`

#### `getUserBalance(address user)` (view)
Obtiene el balance actual de un usuario específico.
- **Returns**: Balance del usuario en wei

#### `getBankStats()` (view)
Obtiene información completa del estado del banco.
- **Returns**: 
  - `totalDeposited`: Total depositado
  - `remainingCapacity`: Capacidad restante
  - `totalDepositOps`: Número de depósitos
  - `totalWithdrawalOps`: Número de retiros

## Instrucciones de Despliegue

### Prerequisitos

- Solidity ^0.8.26
- Framework de desarrollo (Hardhat, Foundry, Truffle, etc.)
- Red Ethereum (mainnet, testnet, o red local)

### Parámetros del Constructor

El contrato requiere dos parámetros durante el despliegue:

```solidity
constructor(uint256 _bankCap, uint256 _withdrawalThreshold)
```

- `_bankCap`: Límite máximo global de depósitos (en wei)
- `_withdrawalThreshold`: Límite máximo de retiro por transacción (en wei)

### Ejemplo de Despliegue

#### Con Hardhat

```javascript
// scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const KipuBank = await ethers.getContractFactory("KipuBank");
    
    // Configuración de ejemplo
    const bankCap = ethers.parseEther("1000");        // 1000 ETH máximo
    const withdrawalThreshold = ethers.parseEther("10"); // 10 ETH por retiro
    
    const kipuBank = await KipuBank.deploy(bankCap, withdrawalThreshold);
    await kipuBank.waitForDeployment();
    
    console.log("KipuBank deployed to:", await kipuBank.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
```

#### Con Foundry

```bash
# Desplegar en red local
forge create --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> src/KipuBank.sol:KipuBank --constructor-args 1000000000000000000000 10000000000000000000

# Desplegar en Sepolia testnet
forge create --rpc-url https://sepolia.infura.io/v3/<PROJECT_ID> --private-key <PRIVATE_KEY> src/KipuBank.sol:KipuBank --constructor-args 1000000000000000000000 10000000000000000000
```

## Cómo Interactuar con el Contrato

### Usando Web3.js

```javascript
const Web3 = require('web3');
const web3 = new Web3('https://your-ethereum-node');

const contractAddress = '0x...'; // Dirección del contrato desplegado
const abi = [...]; // ABI del contrato
const contract = new web3.eth.Contract(abi, contractAddress);

// Depositar ETH
async function deposit(fromAccount, amountInEther) {
    const amount = web3.utils.toWei(amountInEther.toString(), 'ether');
    await contract.methods.deposit().send({
        from: fromAccount,
        value: amount,
        gas: 100000
    });
}

// Retirar ETH
async function withdraw(fromAccount, amountInEther) {
    const amount = web3.utils.toWei(amountInEther.toString(), 'ether');
    await contract.methods.withdraw(amount).send({
        from: fromAccount,
        gas: 100000
    });
}

// Consultar balance
async function getUserBalance(userAddress) {
    const balance = await contract.methods.getUserBalance(userAddress).call();
    return web3.utils.fromWei(balance, 'ether');
}

// Obtener estadísticas del banco
async function getBankStats() {
    return await contract.methods.getBankStats().call();
}
```

### Usando Ethers.js

```javascript
const { ethers } = require('ethers');

const provider = new ethers.JsonRpcProvider('https://your-ethereum-node');
const signer = new ethers.Wallet('your-private-key', provider);
const contract = new ethers.Contract(contractAddress, abi, signer);

// Depositar ETH
async function deposit(amountInEther) {
    const tx = await contract.deposit({
        value: ethers.parseEther(amountInEther.toString())
    });
    await tx.wait();
}

// Retirar ETH
async function withdraw(amountInEther) {
    const amount = ethers.parseEther(amountInEther.toString());
    const tx = await contract.withdraw(amount);
    await tx.wait();
}

// Consultar balance
async function getUserBalance(userAddress) {
    const balance = await contract.getUserBalance(userAddress);
    return ethers.formatEther(balance);
}
```

### Interacción Directa con Remix IDE

1. **Despliegue**:
   - Abrir [Remix IDE](https://remix.ethereum.org/)
   - Cargar el contrato `KipuBank.sol`
   - Compilar con Solidity 0.8.26
   - En Deploy, introducir parámetros del constructor
   - Hacer clic en "Deploy"

2. **Uso**:
   - **Para depositar**: En la sección "deposit", introducir cantidad en el campo "VALUE" y hacer clic en "deposit"
   - **Para retirar**: En "withdraw", introducir cantidad en wei y hacer clic
   - **Para consultar**: Usar las funciones view como "getUserBalance" y "getBankStats"

## Eventos

El contrato emite los siguientes eventos:

```solidity
// Emitido cuando se realiza un depósito
event KipuBank_DepositMade(address indexed user, uint256 amount, uint256 newBalance);

// Emitido cuando se realiza un retiro
event KipuBank_WithdrawalMade(address indexed user, uint256 amount, uint256 remainingBalance);
```

## Errores Personalizados

- `KipuBank_ZeroDepositAmount()`: Intento de depositar 0 ETH
- `KipuBank_ExceedsBankCapacity(uint256, uint256)`: Depósito excede capacidad del banco
- `KipuBank_ZeroWithdrawalAmount()`: Intento de retirar 0 ETH
- `KipuBank_InsufficientBalance(uint256, uint256)`: Balance insuficiente
- `KipuBank_ExceedsWithdrawalThreshold(uint256, uint256)`: Retiro excede umbral
- `KipuBank_TransferFailed(bytes)`: Fallo en transferencia ETH

## Consideraciones de Seguridad

- ✅ **Patrón Checks-Effects-Interactions**: Previene ataques de reentrancy
- ✅ **Validaciones de entrada**: Todos los inputs son validados
- ✅ **Límites configurables**: Protección contra retiros masivos
- ✅ **Manejo seguro de transferencias**: Uso de `call` con validación de éxito
- ✅ **Variables inmutables**: Configuración fija post-despliegue

## Licencia

MIT License

## Autor

Tomas Giardino
