# modbusemu
Программа позволяет эмулировать устройства Modbus и осуществлять доступ к ним по протоколам Modbus RTU  и Modbus TCP. 
При этом, возможен доступ к устройству по обоим протоколам одновременно.

При создании устройства определяются функции Modbus по средствам которых будет осущетсвляться взаимодействием с создаваемым устройством. 
В зависимости от выбранных функций создаются пулы регистров (Coil,Diskret,Holding,Input). Для каждого пула создается 10 000 регистров. 
Адресация регистров пулах начинается с 0.

При выборе типа канала(последовательный и/или сетевой(TCP/IP)),так же, осуществляется выбор протокола. Для последовательного канала - Modbus RTU, для сетевого - Modbus TCP