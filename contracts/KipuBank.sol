//SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*
	*@title Contrato KipuBank
    *@author Tomas Giardino
	* @notice Un smart contract de bóveda bancaria que permite a los usuarios depositar y retirar ETH.
*/

contract KipuBank {

	/* Variables */

    /*
     * @notice Umbral máximo que un usuario puede retirar por transacción
     * @dev Valor fijo establecido durante el despliegue
     */
    uint256 public immutable s_withdrawalThreshold;

    /*
     * @notice Límite máximo global de depósitos que puede manejar el banco
     * @dev Definido durante el despliegue del contrato, no puede ser modificado
     */
    uint256 public immutable s_bankCap;

    /*
     * @notice Total de ETH depositado actualmente en el banco
     * @dev Se actualiza con cada depósito y retiro
     */
    uint256 private s_totalDeposits;
    
    /*
     * @notice Contador total de operaciones de depósito realizadas
     */
    uint256 public s_depositCount;
    
    /*
     * @notice Contador total de operaciones de retiro realizadas
     */
    uint256 public s_withdrawalCount;

    /*
     * @notice Mapeo que almacena el saldo de cada usuario
     * @dev address => balance en ETH
     */
    mapping(address usuario => uint256 valor) public balances;


    /* Events */

    /*
     * @notice Emitido cuando un usuario realiza un depósito exitoso
     * @param user Dirección del usuario que depositó
     * @param amount Cantidad depositada en wei
     * @param newBalance Nuevo balance del usuario después del depósito
     */
    event KipuBank_DepositMade(address indexed user, uint256 amount, uint256 newBalance);
    
    /*
     * @notice Emitido cuando un usuario realiza un retiro exitoso
     * @param user Dirección del usuario que retiró
     * @param amount Cantidad retirada en wei
     * @param remainingBalance Balance restante del usuario después del retiro
     */
    event KipuBank_WithdrawalMade(address indexed user, uint256 amount, uint256 remainingBalance);
    


    /* Errors */

    /*
     * @notice Error lanzado cuando se intenta depositar una cantidad igual a cero
     */
    error KipuBank_ZeroDepositAmount();
    
    /*
     * @notice Error lanzado cuando el depósito excedería el límite global del banco
     * @param attemptedAmount Cantidad que se intentó depositar
     * @param availableCapacity Capacidad disponible restante
     */
    error KipuBank_ExceedsBankCapacity(uint256 attemptedAmount, uint256 availableCapacity);
    
    /*
     * @notice Error lanzado cuando se intenta retirar una cantidad igual a cero
     */
    error KipuBank_ZeroWithdrawalAmount();
    
    /*
     * @notice Error lanzado cuando el usuario intenta retirar más de lo que tiene
     * @param requestedAmount Cantidad solicitada para retiro
     * @param availableBalance Balance disponible del usuario
     */
    error KipuBank_InsufficientBalance(uint256 requestedAmount, uint256 availableBalance);
    
    /*
     * @notice Error lanzado cuando el retiro excede el umbral permitido por transacción
     * @param requestedAmount Cantidad solicitada para retiro
     * @param maxAllowed Máximo permitido por transacción
     */
    error KipuBank_ExceedsWithdrawalThreshold(uint256 requestedAmount, uint256  maxAllowed);
    
    /*
     * @notice Error lanzado cuando la transferencia de ETH falla
     */
    error KipuBank_TransferFailed(bytes mesgError);


    /* Modifiers */

    /*
     * @notice Modificador para validar que el monto a depositar no sea cero
     * @param _amount Cantidad a validar
     */
    modifier nonZeroAmountToDeposit(uint256 _amount){
        if (_amount == 0)
            revert KipuBank_ZeroDepositAmount();
        _;
    }

    /*
     * @notice Modificador para validar que el monto a retirar no sea cero
     * @param _amount Cantidad a validar
     */
    modifier nonZeroAmountToWithdraw(uint256 _amount){
        if (_amount == 0)
            revert KipuBank_ZeroWithdrawalAmount();
        _;
    }
    
    /*
     * @notice Modificador para validar que el usuario tenga balance suficiente
     * @param _user Dirección del usuario
     * @param _amount Cantidad requerida
     */
    modifier hasSufficientBalance(address _user, uint256 _amount) {
        if (balances[_user] < _amount) {
            revert KipuBank_InsufficientBalance(_amount, balances[_user]);
        }
        _;
    }

    /*
     * @notice Modificador para validar que el depósito no exceda la capacidad del banco
     * @param _totalDeposits La cantidad total depositada en el banco hasta el momento
     * @param _maxDepositAllowed Límite máximo global de depósitos que puede manejar el banco
     */
    modifier verifyBankCapacity(uint256 _totalDeposits, uint256 _maxDepositAllowed, uint256 _amount) {
        uint256 newTotalDeposits = _totalDeposits + _amount;
        if (newTotalDeposits > _maxDepositAllowed) {
            revert KipuBank_ExceedsBankCapacity(_amount, _maxDepositAllowed - _totalDeposits);
        }
        _;
    }

    /*
     * @notice Modificador para validar que el retiro no exceda el umbral permitido
     * @param _amount Cantidad a validar
     * @param _withdrawalThreshold Umbral máximo que puede retirarse por transacción
     */
    modifier verifyWithdrawalThreshold(uint256 _amount, uint256 _withdrawalThreshold) {
        if (_amount > _withdrawalThreshold) {
            revert KipuBank_ExceedsWithdrawalThreshold(_amount, _withdrawalThreshold);
        }
        _;
    }

    /*
     * @notice Modificador para validar que la direccion del destinatario no se modifique durante el retiro de ETH
     * @param _finalAddress Direccion a validar
     * @dev Modificador para la prevención de reentradas
     */
    modifier verifyFinalAddress(address _finalAddress){
        _;
        if (msg.sender != _finalAddress)
            revert KipuBank_TransferFailed("La direccion del usuario cambio durante el retiro de ETH.");
        _;
    }


    /* Functions */

    /*
     * @notice Inicializa el contrato KipuBank con los parámetros especificados
     * @param _bankCap Límite máximo global de depósitos en wei
     * @param _withdrawalThreshold Límite máximo de retiro por transacción en wei
     * @dev Ambos parámetros deben ser mayores que cero
     */
    constructor (uint256 _bankCap, uint256 _withdrawalThreshold) nonZeroAmountToWithdraw(_withdrawalThreshold) nonZeroAmountToDeposit(_bankCap) {
        s_bankCap = _bankCap;
        s_withdrawalThreshold = _withdrawalThreshold;
        s_totalDeposits = 0;
        s_depositCount = 0;
    }


    /* external */

    /*
     * @notice Permite a los usuarios depositar ETH en su bóveda personal
     * @dev Función payable que acepta ETH y actualiza el balance del usuario
     * @dev Sigue el patrón checks-effects-interactions
     */
    function deposit() external payable nonZeroAmountToDeposit(msg.value) verifyBankCapacity(s_totalDeposits, s_bankCap, msg.value) {
        
        // Actualizar el estado antes de cualquier interacción externa
        balances[msg.sender] += msg.value;
        s_totalDeposits += s_totalDeposits + msg.value;
        s_depositCount++;
        
        // Emitir evento de deposito exitoso
        emit KipuBank_DepositMade(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /*
     * @notice Permite a los usuarios retirar ETH de su bóveda personal
     * @param amount Cantidad a retirar en wei
     * @dev Solo permite retirar hasta el umbral establecido por transacción
     */
    function withdraw(uint256 _amount) external payable nonZeroAmountToWithdraw(_amount) hasSufficientBalance(msg.sender, _amount) { 
        //Actualizar el estado antes de la transferencia
        balances[msg.sender] -= _amount;
        s_totalDeposits -= _amount;
        s_withdrawalCount++;
        
        //Transferir ETH de manera segura
        _safeTransfer(msg.sender, _amount);
        
        emit KipuBank_WithdrawalMade(msg.sender, _amount, balances[msg.sender]);
    }


    /* private */

    /*
     * @notice Realiza una transferencia segura de ETH
     * @param to Dirección destinataria
     * @param amount Cantidad a transferir en wei
     * @dev Función privada que maneja las transferencias de ETH de forma segura
     */
    function _safeTransfer(address to, uint256 amount) private verifyFinalAddress(to) {
        (bool success, bytes memory mesgError) = payable(to).call{value: amount}("");
        if (!success) {
            revert KipuBank_TransferFailed(mesgError);
        }
    }


    /* View & Pure */

    /*
     * @notice Obtiene el balance actual de un usuario específico
     * @param user Dirección del usuario a consultar
     * @return balance Balance actual del usuario en wei
     */
    function getUserBalance(address user) external view returns (uint256 balance) {
        return balances[user];
    }
    
    /*
     * @notice Obtiene información completa del estado del banco
     * @return totalDeposited Total de ETH depositado actualmente
     * @return remainingCapacity Capacidad restante para nuevos depósitos
     * @return totalDepositOps Número total de operaciones de depósito
     * @return totalWithdrawalOps Número total de operaciones de retiro
     */
    function getBankStats() external view returns (uint256 totalDeposited, uint256 remainingCapacity, uint256 totalDepositOps, uint256 totalWithdrawalOps) {
        return (
            s_totalDeposits,
            s_bankCap - s_totalDeposits,
            s_depositCount,
            s_withdrawalCount
        );
    }
}
