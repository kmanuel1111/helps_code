# 📘 Guía de Comandos MongoDB

Esta guía proporciona una referencia rápida y clara de los comandos más utilizados en MongoDB. Ideal para desarrolladores, administradores de bases de datos y entusiastas de la tecnología.

---

## 🧭 Navegación Básica

- [📘 Guía de Comandos MongoDB](#-guía-de-comandos-mongodb)
  - [🧭 Navegación Básica](#-navegación-básica)
    - [🔧 Control del servicio MongoDB](#-control-del-servicio-mongodb)
    - [🧠 Comandos básicos de mongosh](#-comandos-básicos-de-mongosh)
    - [📂 Navegación y gestión de bases de datos](#-navegación-y-gestión-de-bases-de-datos)
    - [📥 Inserción de documentos](#-inserción-de-documentos)
    - [🔍 Consultas](#-consultas)
      - [Consultas generales](#consultas-generales)
      - [Consultas con operadores](#consultas-con-operadores)
      - [Operadores de comparación](#operadores-de-comparación)
      - [Operadores Logicos](#operadores-logicos)
      - [Operadores de Elemento](#operadores-de-elemento)
      - [Operadores de Evaluacion](#operadores-de-evaluacion)
      - [Operadores de Array](#operadores-de-array)
      - [Consultas anidadas con operadores de comparación](#consultas-anidadas-con-operadores-de-comparación)
    - [✏️ Actualizaciones](#️-actualizaciones)
    - [🗑️ Eliminación](#️-eliminación)
    - [🛠️ Administración](#️-administración)

### 🔧 Control del servicio MongoDB

```bash
sudo systemctl status mongod       # Ver estado del servicio
sudo systemctl start mongod        # Iniciar servicio
sudo systemctl stop mongod         # Detener servicio
sudo systemctl restart mongod      # Reiniciar servicio
sudo systemctl enable mongod       # Activar al iniciar el sistema
sudo systemctl disable mongod      # Desactivar al iniciar el sistema
```

### 🧠 Comandos básicos de mongosh

```bash
mongosh --help                             # Ver ayuda general
mongosh "mongodb://localhost:27017/admin"  # Conexión por URI
mongosh --port 27018                       # Conexion por puerto
mongosh --port 27017 -u "kzambrano" -p "kmanuel11" --authenticationDatabase admin # Conexion por puerto con autenticacion
```

### 📂 Navegación y gestión de bases de datos

```js
show dbs                         // Listar bases de datos
use NombreBaseDeDatos            // Cambiar de base de datos
db                               // Mostrar base actual
show collections                 // Listar colecciones
```

### 📥 Inserción de documentos

```bash
# Importar a la base de datos documentos
# * --host Server a donde se conecta (Predeterminado localhost)
# * --port Puerto a donde se conecta (Predeterminado 27017)
# * --d Base de datos a donde importar los archivos
# * --c Coleccion de la base de datos donde importar los archivos
# * --jsonArry Dice que el documento a importar contiene arrays de json
# * --drop Elimina la base de datos y collecion antes de realizar la importacion
# * --authenticationDatabase Base de datos a donde se conecta
# * -u Usuario de la base de datos
# * -p Contraseña de la base de datos
mongoimport empleado.json --host localhost --port 27018 -d startup -c empleados --jsonArray --drop --authenticationDatabase admin -u "kzambrano" -p "kmanuel11"
```

```js
// Crear colección
db.createCollection("nombreColeccion");

// Insertar uno
db.nombreColeccion.insertOne({ campo1: "valor", campo2: 123 });

 // Insertar varios
db.nombreColeccion.insertMany([{...}, {...}]);

 // Insertar varios sin importar duplicidad de _id(keys)
db.nombreColeccion.insertMany([{...}, {...}]{ordered:false});
```

### 🔍 Consultas

#### Consultas generales

```js
// Obtener todos los documentos de la colección
db.nombreColeccion.find();

// Mostrar documentos con formato legible (indentado)
db.tipo_cafe.find().pretty();

// Convertir el cursor en un array de documentos
db.empleado.find().toArray();

// Iterar sobre cada documento usando forEach (consume más memoria)
db.empleado.find().forEach((cafeData) => {
  printjson(cafeData);
});

// Proyección: mostrar solo campos específicos (oculta _id)
db.empleado.find({}, { nombre: 1, _id: 0 });

// Mostrar un solo el primer documento que encuentra con una respectica condicion
db.empleado.findOne({ stock: 0 });

// Acceder directamente a un campo tipo array usando findOne
db.empleado.findOne({ nombre: "Lewis Coleman" }).dia_laborable;

// Buscar documentos donde un valor esté dentro de un array
db.empleado.findOne({ dia_laborable: "Jueves" });

// Buscar solo que dentro de la array se cumpla la condicion
db.product.find({ branchOffice: ["Alabama"] });
db.product.find({ branchOffice: ["Alabama", "California"] });

// Buscar documentos con subdocumentos anidados (objeto dentro de objeto)
db.tipo_cafe.find({ "venta.pago": "Efectivo" });
db.tipo_cafe.find({ "venta.detalle.responsable": "Carlos Moreno" });
```

#### Consultas con operadores

#### Operadores de comparación

Estos operadores permiten filtrar documentos en consultas `find()` según condiciones específicas.

- **$eq** _Igua que_

```js
// Devuelve los documentos que coinciden con los valores especificados
db.product.find({ productName: { $eq: "Chai" } });
```

- **$ne** _Distinto de_

```js
// Devuelve los documentos que NO coinciden con el valor especificado
db.product.find({ unitsInStock: { $ne: 0 } });

// Devuelve los documentos donde branchOffice NO CONTIENE es "Florida"
db.product.find({ branchOffice: { $ne: "Florida" } });

// Devuelve los documentos donde branchOffice NO es "Florida" EXACTAMENTE
db.product.find({ branchOffice: { $ne: ["Florida"] } });
```

- **$in** _Dentro de un conjunto_

```js
// Devuelve los documentos donde branchOffice es "Alabama"
db.product.find({ branchOffice: { $in: ["Alabama"] } });

// Devuelve los documentos donde branchOffice es "Alabama" o "California"
db.product.find({ branchOffice: { $in: ["Alabama", "California"] } });
```

- **$nin** _Fuera de un conjunto_

```js
// Devuelve los documentos donde branchOffice NO es "Alabama"
db.product.find({ branchOffice: { $nin: ["Alabama"] } });

// Devuelve los documentos donde branchOffice NO es "Alabama" ni "California"
db.product.find({ branchOffice: { $nin: ["Alabama", "California"] } });
```

- **$gt** _Mayor que_

```js
db.product.find({ unitsInStock: { $gt: 17 } });
```

- **$lt** _Menor que_

```js
db.product.find({ unitsInStock: { $lt: 10 } });
```

- **$gte** _Mayor o igual que_

```js
db.product.find({ unitsInStock: { $gte: 12 } });
```

- **$nin** _Fuera de un conjunto_

```js
db.product.find({ unitsInStock: { $lte: 15 } });
```
#### Operadores Logicos

- **$and** _Este y este_

```js
db.product.find({$and:[{ "discountDay.Monday": {$gt:0.25},branchOffice:"Florida"}]});
db.product.find({$and:[{ "branchOffice": "Alabama","branchOffice":"Florida"}]});

```
- **$or** _Este o este_
```js
db.product.find({$or:[{"discountDay.Monday":{$lt:0.15}},{"discountDay.Monday":{$gt:0.30}}]})
```

- **$nor** _Ni este, Ni este_

```js
db.product.find({$nor:[{"categories.suppliers.region":null},{"categories.suppliers.country":"UK"}]})
```
- **$not** _Negar_
```js
db.product.find({ unitsInStock: {$not:{ $gt: 17 }} });
db.product.find( {"categories.categoryName":{$not:{$in:["Beverages","Seafood","Confections","Condiments"]  } } });
``` 

#### Operadores de Elemento

- **$exists** _Existe el Parametro_
```js
// Mostrar los que existen con el cambo de age
db.employee.find({ age:{$exists:true }}  );

// Mostrar los que NO existen con el cambo de age
db.employee.find({ age:{$exists:false }}  );

// Mostrar los que existen y agregar otro operador adicional
db.employee.find({ age:{$exists:true, $gt: 35 }}  );
```

- **$type** _Consultar por tipo de datos_
```js
//Buscar por tipo de dato entero (Number)
db.employee.find( { homePhone:{$type:"number" } } );

// Buscar por varios tipo de datos, (Entero y cadena)
db.employee.find({homePhone:{$type:["number","string"]}  });
```

#### Operadores de Evaluacion

- **$regex** _Buscar coincidencias_
```js
// Buscar coincidencias por la cadena de texto
db.employee.find( {description:{$regex:"travel"  } } );

// Buscar coincidencias sin importar mayusculas o minusculas
db.employee.find( {title:{$regex:"Support",$options:"i"  } } );

// Buscar documentos que empiecen por (And)
db.employee.find( { firstName:{$regex:"^And"}} );

// Buscar documentos que terminen por (y)
db.employee.find( { firstName:{$regex:"y$"}} );

// Usar el operador regex sin escribirlo con //
db.employee.find( { description:/travel/} );
db.employee.find( { title:/Support/i} );
db.employee.find( { title:/^And/} );
db.employee.find( { title:/y$/} );
```
- **$expr** _Comparar expresiones_
```js
// Comparar si es mayor que con ayuda del operador de comparacion
db.employee.find({$expr:{$gt:["$delay","$tolerance" ]} });
// Comparar si es menor que con ayuda del operador de comparacion
db.employee.find({$expr:{$lt:["$delay","$tolerance" ]} });
// Comprar si igual con ayuda del operador de comparacion
db.employee.find({$expr:{$eq:["$delay","$tolerance" ]} });
```

- **$mod** _Divisor_
```js
// NO ACEPTA DECIMALES
// Muestra los documentos que cuando la edad sea divisible entre 2 (par)
db.employee.find({age:{$mod:[2,0]} });
// Muestra los documentos que cuando la edad NO sea divisible entre 2 (impar)
db.employee.find({age:{$mod:[2,1]} });
// Muestra los documentos que cuando la edad sea divisible entre 3 
db.employee.find({age:{$mod:[3,0]} });
```

#### Operadores de Array

- **$all** _Coincidencia con todos los valores_
```js
// Buscar documentos que coincidan con todos los valores especificados
db.product.find({ tags: { $all: ["fruit", "organic"] } });
// Equivalente a 
db.product.find({$and:[{tags:"fruit"},{tags:"organic"}]});0
// Equivalente a 
db.product.find({tags:{$in:["fruit","organic"]}});
```

- **$elemMatch** _Coincidencia con un elemento_
```js
// Buscar documentos con un elemento que coincida con la condición
db.product.find({ tags: { $elemMatch: { $eq: "fruit" } } });
```
- **$size** _Tamaño del array_
```js
// Buscar documentos con un array de tamaño específico
db.product.find({ tags: { $size: 2 } });
```

#### Consultas anidadas con operadores de comparación

```js
db.product.find({
  "categories.categoryName": { $in: ["Dairy Products", "Grains/Cereals"] },
});

db.product.find({
  "discountDay.Monday": { $gt: 0.25 },
});
```

### ✏️ Actualizaciones

```js
// Actualizar un documento
db.nombreColeccion.updateOne(
  { campo: "valor" },
  { $set: { campo_actualizado: "nuevo_valor" } }
);

// Actualizar varios Documentos
db.nombreColeccion.updateMany(
  { campo: "valor" },
  { $set: { campo_actualizado: "nuevo_valor" } }
);
```

Ejemplo

```js
db.tipo_cafe.updateOne(
  { _id: ObjectId("68b1e1074e0d7660f689b041") },
  { $set: { nombre: "José" } }
);
```

### 🗑️ Eliminación

```js
db.nombreColeccion.deleteOne({ condición }); // Eliminar uno
db.nombreColeccion.deleteMany({ condición }); // Eliminar varios
```

### 🛠️ Administración

```js
db.nombreColeccion.createIndex({ campo: 1 }); // Crear índice
db.nombreColeccion.getIndexes(); // Ver índices
db.nombreColeccion.stats(); // Estadísticas de colección
```
