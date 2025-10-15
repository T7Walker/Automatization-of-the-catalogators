### Catalogador pruebas automatización: Python, PowerShell, API´s, IA, PowerAutomate







##### Promoción a pruebas - Incidentes Y Dirección de aplicaciones: Python, PowerShell, API´s, IA, PowerAutomate



**0 paso:** Al correo llega un correo de la promoción, PowerAutomate se ejecuta para así mismo ejecutar toda esta lógica

**1 paso:** Acceder a la historia de usuario asociada y verificar a que dirección de atención pertenece para asi saber a quien tiene que etiquetar

**2 paso:** Obtener el link que esta en el apartado de "Control de paso FM-169" en azure para luego entrar a revisar los archivos manual y control de pasos. Cabe aclarar que estos archivos

 	pasaran por powershell, convirtiéndolos en variables para que asi la IA pueda hacer la comparación de los datos



 	**2.1 paso:** Primeramente se revisa el control de pasos que esta en file server, para acceder a la ruta del file server, se debe buscar una variable que esta en el

 	control de pasos de azureDevOps que tiene las rutas tanto de desarrollo, pruebas, preproducción.



 	**2.2 paso:** primeramente se revisa en el control de pasos de file server lo siguiente

 		- El código de control de paso comparado con el de azure

 		- Si la casilla que se llama "Parametrización" esta marcada ya sea con "M" o "N"

 		- La cantidad de objetos del control de pasos a comparación a la promoción de AzureDeVOps

 		- Los nombres de los objetos deben ser idénticos a los obejtos puestos en AzureDevOps

 		- Si encuentran clases en el control de pasos ".CLASS", se debe seguir este proceso:

 

 			**2.2.1 paso:** Se debe buscar en los links si hay algunos que digan "Solicitud de fuentes {Nombre de la fuente, que empieza por bmm}", si los hay, que coincidan con las fuentes

 			puestas en los objetos de control de pasos de Azure y los del file server

 			**2.2.2 paso:** Revisar el estado de esa solicitud de fuente, si el estado esta "entregado", se continua con flujo con normalidad; pero si es cualquier otro se debe ejecutar un

 			PowerAutomate para notificar a Luis Gerardo , camilo Ceron, Didier Joaqui que diga lo siguiente:

 

 			"Cordial saludo

 			Se les solicita que cordialmente atiendan esta solicitud {Numero de HU} debido a que {descripción breve del problema}, muchas gracias"



 			Se cierra el ciclo y dejas de ejecutar



  		- En el apartado Recomendaciones y procesos para ejecutar para validación de funcionalidad, revisar si no hay otros pasos de los cuales dependa el paso actual



 	**2. paso:** Una vez confirmado que todo esta correcto en el control de paso, accederemos al manual técnico para revisar lo siguiente

 		- El código de control de paso comparado con el de azure

 		- Hay un recuadro en el cual estará marcado si tiene parametria o no. Para que se ejecute con lógica esta parte se debe basar en la información

 		que esta en Azure, si tiene o no parametria y también en el control de paso que esta en el file server



 		**(PROPUESTA): Se puede añadir una variable en control de pasos que sea booleana para determine si hay parametria para facilitar el**

 		**procesamiento de la información para la IA, campo obligatorio**





 	Si se encuentra algún error, se debe hacer lo siguiente: Ejecutar un powershell con .NET, que tomara una captura de pantalla del problema encontrado, luego se ira a la

 		tarea de promoción y en la discusión pondrá el siguiente comentario:



 		"{desarrollador y lider desarrollo}

 		Cordial saludo

 		Se solicita hacer la corrección de {Descripción breve del problema ocurrido}, estoy al pendiente

 		{Pegar la captura de pantalla}"



 		Después de esto, esperar a que respondan al correo para continuar con el proceso y ejecutar un powerAutomate para enviar un correo a Didier Joaqui



**3 paso:** Cuando la verificación fue hecha, se puede ejecutar el powershell que copia la carpeta de desarrollo a pruebas con su respectivo aplicativo, la ruta la proporciona la IA por medio

 	de su API, Python pasa esa variable a powershell y este mismo lo ejecuta. Cabe recalcar que por medio de este mismo py se pasara la ruta de pruebas.



**4 paso:** Se debe pegar esta ruta en la variable ruta de pruebas



**5 paso:** Poner el estado en Testing



**6 paso**: En la discusión poner lo siguiente:

 

 	"{etiquetar a juan Felipe y control de requerimientos}

 	Codial saludo

 

 	Se informa que el soporte {numero de control de pasos} se encuentra en pruebas a espera de su

 	solicitud de aplicación

 	Por favor confirmar la fecha y ambiente de aplicación"

 	Aplicativo {nombre del aplicativo]



 	RUTA: {ruta de pruebas}



 	¡Muchas Gracias!"



 	Y se sube el comentario



* ##### Aplicación en pruebas incidentes y dirección de aplicaciones: Python, API´S, PowerAutomate, PowerShell



**0 paso:** Al correo llega un correo de la aplicación en x ambiente, PowerAutomate se ejecuta para así mismo ejecutar toda esta lógica





**1 paso:** Comprobar de que dirección de atención pertenece para luego entrar al apartado de "Control de paso FM-169" y buscar la variable de ruta de pruebas

**2 paso:** A través de la API, se pasa esa ruta al py para que este mismo pase esa variable al ejecutable de PowerShell, se ejecuta, se devuelven la información a la IA

**3 paso:** cuando se tenga la información, se confirma que no haya pasos de los cuales dependa el paso actual, en caso de que sea asi, se debe seguir este proceso:

 	**3.1 paso:** Si hay un paso del cual depende el actual, se debe confirmar si en Azure existe ese paso y si se encuentra en el mismo ambiente que se pide aplicar el actual, además

 		se debe verificar la fecha de cuando fue la aplicación del paso del cual depende el actual porque pruebas 1 y 2 se restablecen cada 15 días y pruebas 3 cada mes.



 		Para evitar confusiones por parte de la IA, se integrara en código una variable en la cual determine si se puede o no utilizar el ambiente, debido a que no hay una

 		formalización de cuando esta reservado un ambiente o no, se debe hacer de manera manual.



 		**(PROPUESTA): Estipular y imponer una task en la cual se notifique en ese dia se restablecerá ese ambiente y también si se reservara**

 	\*\*(PROPUESTA): Estipular en la HU un campo para determinar si hay soportes de los cuales depende el soporte actual\*\*







 		Si el paso no esta aplicado en el ambiente al cual se quiere aplicar el actual, se debe ejecutar un PowerAutomate para hacer una tarea de aplicación de ese soporte en

 		el ambiente que se necesite (este ciclo se debe repetir hasta que ya no se encuentren dependencias en los soportes).



**4 paso:** Si no hay pasos de los cuales depender o ya fueron aplicados, se ejecuta un PowerAutomate que añade un nuevo ítem de "Tarea de aplicación en Pruebas",

 	con un titulo de "Pruebas Aplicar {numero} en P {ambiente donde se aplicara este soporte}" y se añade el ítem.



**5 paso:** Se llena la tarea de aplicación con los parámetros requeridos:



 		**- Ruta de pruebas**

 		**- Código de control de paso**

 		**- Dirección de atención**





 		**- Ambiente core o no core**

 	**- Etiquetar:** en el recuadro de texto, se debe etiquetar al equipo de infraestructura con el siguiente texto:







 		"Cordial saludo

 		se solicita aplicar el soporte {Código de control de pasos} en el ambiente de Pruebas {ambiente donde se necesita aplicar}"



 		- **Asignar:** La tarea se asigna a líder del equipo de infraestructura



 	(Todo este proceso se hará por medio de un PowerAutomate), por ultimo se guarda.



##### Actualización de archivos: Python, API´S, PowerAutomate



**0 paso:** Al correo llega un correo de la confirmación, Powerautomate se ejecuta para así mismo ejecutar toda esta lógica

**1 paso:** La IA analiza y le manda la descripción a través de una variable al código de py

**2 paso.** El código procesa y ejecuta un powershell el cual copiara los archivos de la ruta de desarrollo a pruebas, en pocas palabras, hará el mismo proceso que hace git pull y git push

 	cualquier cambio que se haga en los archivos, se vera reflejado en la carpeta donde se agregará y se creara un registro en texto plano con los datos de los cambios hechos.

**3 paso:** luego este py subirá esta captura de pantalla como ".atachment" a AzureDevOps.

**4 paso:** Se ejecuta un PowerAutomate que respondera la tarea de promoción y luego la HU

**5 paso:** Aquí se reciclara el código de aplicación en pruebas pero en lugar de Aplicar será Actualizar en el ultimo ambiente en donde se aplico el soporte

##### 

##### Confirmación de aplicación: Python, API´S, PowerAutomate



**0 paso:** Al correo llega un correo de la confirmación, Powerautomate se ejecuta para así mismo ejecutar toda esta lógica

**1 paso:** el comentario de la confirmación se manda a través de una variable a la IA, para ella procese la información, si hay











 





 

