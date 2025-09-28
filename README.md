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


## Autor

Tomas Giardino
