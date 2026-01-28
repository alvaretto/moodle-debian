# Instalación de Moodle Portátil - Guía Completa

## Contexto del Proyecto

| Aspecto | Especificación |
|---------|----------------|
| **Hardware servidor** | Portátil 12GB RAM (4+8 DDR3), SSD 125GB |
| **Sistema Operativo** | Debian 13 "Trixie" con XFCE minimal |
| **Usuarios** | 80-100 estudiantes simultáneos |
| **Dispositivos estudiantes** | Tablets Windows 10 (no muy modernas) vía WiFi |
| **Contenido** | Archivos XML de [r-exams-icfes-matematicas](https://github.com/alvaretto/proyecto-r-exams-icfes-matematicas-optimizado) |
| **Movilidad** | Servidor viaja entre dos ubicaciones con routers diferentes |
| **Backups** | Snapshots automáticos con Timeshift + backup Moodle |

**Última actualización**: Enero 2026 - Actualizado para Moodle 5.1 + PHP 8.4 sobre Debian 13.3

---

## ⚠️ Notas Importantes de Instalación

### Lecciones Aprendidas (Actualizado tras instalación real)

**✅ QUÉ HACER**:

1. **Marcar XFCE en el instalador** - En "Selección de software", marca "XFCE" junto con SSH y utilidades estándar
2. **Verificar modo UEFI** - Si tu BIOS lo soporta, arrancar en UEFI (no Legacy)
3. **Usar BTRFS con LVM** - Permite snapshots con Timeshift
4. **Configurar Timeshift con RSYNC en Legacy** - Si instalaste en Legacy/MBR, usa modo RSYNC (no BTRFS nativo)

**❌ QUÉ NO HACER**:

1. ~~Instalar sistema base sin escritorio~~ - Causa problemas con lightdm y NetworkManager
2. ~~Instalar XFCE manualmente después~~ - Mejor hacerlo desde el instalador
3. ~~Usar particionado guiado sin cambiar a BTRFS~~ - ext4 no permite snapshots eficientes
4. ~~Intentar snapshots BTRFS nativos en Legacy/MBR~~ - Usa RSYNC en su lugar

Estas recomendaciones vienen de una instalación real donde se encontraron y resolvieron estos problemas.

---

## Arquitectura de Red

### Ubicación A: Preparación (Casa/Oficina del Profesor)

```
    ┌─────────────┐
    │  INTERNET   │
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │  ROUTER A   │ ← Router del profesor (con Internet)
    │ 192.168.0.1 │
    └──────┬──────┘
           │ Cable RJ45
    ┌──────┴──────┐
    │  PORTÁTIL   │
    │   MOODLE    │ ← IP dinámica (ej: 192.168.0.105)
    │   + XFCE    │   Accesible como: moodle.local
    └─────────────┘
```

### Ubicación B: Aula de Clase

```
    ┌─────────────┐
    │  INTERNET   │ ← Opcional (estudiantes NO tienen acceso)
    └──────┬──────┘
           │
    ┌──────┴──────┐
    │  ROUTER B   │ ← Router fijo del aula
    │ 192.168.1.1 │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     │           │
  Cable RJ45    WiFi
     │           │
┌────┴────┐  ┌───┴───────────────────┐
│PORTÁTIL │  │  80-100 TABLETS       │
│ MOODLE  │  │  Windows 10           │
│         │  │  Acceden a:           │
│moodle.local│  │  http://moodle.local  │
└─────────┘  └───────────────────────┘
```

---

## Solución: mDNS (Multicast DNS)

### ¿Por qué mDNS?

El problema: El portátil obtiene **IP diferente** en cada router:

- Router A: `192.168.0.105`
- Router B: `192.168.1.50`

Con mDNS, el servidor se anuncia como **`moodle.local`** y los dispositivos lo encuentran automáticamente sin importar la IP.

### Compatibilidad

| Sistema | Soporte mDNS |
|---------|--------------|
| Windows 10/11 | Soportado nativamente (desde 2018) |
| Linux | Requiere Avahi |
| Android | Soportado |
| iOS/macOS | Soportado (Bonjour) |

Fuente: [ArchWiki - Avahi](https://wiki.archlinux.org/title/Avahi)

---

# PARTE 1: Instalación del Sistema Base

## 1.1 Descargar Debian 13

1. Ir a [Debian Download](https://www.debian.org/download)
2. Descargar **Debian 13.3 "Trixie" netinst** para amd64 (64-bit PC)

   - Archivo: `debian-13.3.0-amd64-netinst.iso` (~400MB)
3. Crear USB booteable:

   - **Linux**: `sudo dd if=debian-13.3.0-amd64-netinst.iso of=/dev/sdX bs=4M status=progress && sync`
   - **Windows**: Usar [Rufus](https://rufus.ie/) o [balenaEtcher](https://www.balena.io/etcher/)

Fuentes: [Debian Download](https://www.debian.org/download), [Debian 13.3 Release Notes](https://www.debian.org/News/2026/20260110)

---

## 1.2 Arrancar desde USB y Configurar UEFI

### Paso 1: Verificar y Configurar Modo UEFI (CRÍTICO)

**¿Por qué es importante?**

Existen dos modos de arranque:

| Modo | Tabla Particiones | Estado | Recomendación |
|------|-------------------|--------|---------------|
| **UEFI** | GPT (moderno) | ✅ Actual | **Usar este** |
| **Legacy/BIOS** | MBR (antiguo, límite 2TB) | ⚠️ Obsoleto | Evitar |

**IMPORTANTE**: Si arrancas en modo Legacy por error, el instalador te preguntará por particiones "primarias" o "lógicas". Esto indica que NO estás en UEFI. Sigue estos pasos para corregirlo.

### Paso 2: Acceder al BIOS/UEFI

1. **Insertar USB** y reiniciar el portátil
2. **Acceder al BIOS/UEFI** al arrancar:

   - **HP**: Presionar `Esc` luego `F10`, o solo `F10`
   - **Dell**: Presionar `F2` o `F12`
   - **Lenovo**: Presionar `F1`, `F2` o `Enter` luego `F1`
   - **Asus**: Presionar `F2` o `Del`
   - **Acer**: Presionar `F2` o `Del`
   - Buscar mensaje como "Press F2 for Setup" o "Press F12 for Boot Menu"

### Paso 3: Configurar UEFI (MUY IMPORTANTE)

Una vez dentro del BIOS/UEFI, busca y configura:

#### A. Si Tu BIOS Tiene Opción UEFI (Portátiles 2010+)

**Configuraciones principales**:

```
┌──────────────────────────────────────────┐
│ Boot Mode / Boot Mode Select            │
│   [x] UEFI                  ← SELECCIONAR│
│   [ ] Legacy                             │
│   [ ] Both (CSM Enabled)                 │
└──────────────────────────────────────────┘
```

**Otras configuraciones importantes**:

1. **Boot Mode** o **Boot List Option**:

   - Cambiar de `Legacy` a **`UEFI`**
   - O de `Both` a **`UEFI Only`**

2. **CSM (Compatibility Support Module)**:

   - Cambiar a **`Disabled`**
   - (CSM activa compatibilidad con Legacy, no lo queremos)

3. **Secure Boot** (opcional):

   - Puede estar `Enabled` o `Disabled`
   - Debian funciona con ambos
   - Si tienes problemas, prueba `Disabled`

4. **Fast Boot** (opcional):

   - Recomendado: **`Disabled`** durante instalación
   - Puedes activarlo después

#### B. Si Tu BIOS NO Tiene Opción UEFI (Portátiles Antiguos)

**Síntomas**: No encuentras opciones "UEFI", "Boot Mode", "CSM" en ninguna pestaña del BIOS.

**Ejemplo de BIOS antiguos**:

- Phoenix SecureCore
- Award BIOS
- AMI BIOS (versiones pre-2010)

**En este caso**:

1. **SATA Mode** (si existe):

   - Cambiar de `IDE` a **`AHCI`**
   - Ubicación típica: Pestaña "Main" o "Advanced"
   - **Razón**: AHCI es más moderno, soporta TRIM para SSD

2. **Boot Order**:

   - Mover USB a primera posición
   - Aparecerá como "USB HDD:" o "USB-HDD" (no dice UEFI)

3. **Aceptar la limitación**:

   - Instalarás con tabla **MBR** (antigua pero funcional)
   - Durante particionado, el instalador **preguntará** "¿Primaria o Lógica?" (esto es normal)
   - Ver sección **"1.4B - Particionado para BIOS Legacy"** más abajo

### Paso 4: Cambiar Orden de Arranque

1. Buscar sección **Boot Order** o **Boot Priority**
2. Mover el **USB** a la primera posición
3. Asegurarte de seleccionar la opción que diga **UEFI: [nombre del USB]**

   - Correcto: `UEFI: SanDisk 8GB`
   - Incorrecto: `USB HDD: SanDisk` (esto es Legacy)

### Paso 5: Guardar y Salir

1. Presionar **F10** (o la tecla indicada para "Save & Exit")
2. Confirmar con "Yes"
3. El portátil reiniciará desde el USB en modo UEFI

### Verificación Rápida: ¿Estoy en UEFI o Legacy?

**Durante el instalador**:

- ✅ **UEFI detectado**: El particionador NO pregunta "¿Primaria o Lógica?" y crea automáticamente partición EFI
- ❌ **Legacy detectado**: El particionador pregunta "¿Crear partición primaria o lógica?"

**Si detectaste Legacy**:

1. Reinicia presionando `Ctrl+Alt+Del`
2. Vuelve al BIOS/UEFI (Paso 2)
3. Verifica la configuración (Paso 3)

---

## 1.3 Instalador Gráfico de Debian 13

### Pantalla de Boot del Instalador

Verás un menú con varias opciones:

```
┌─────────────────────────────────────┐
│  Debian GNU/Linux installer boot   │
│                                     │
│  ▸ Graphical install                │
│    Install                          │
│    Advanced options...              │
│    Help                             │
│    Install with speech synthesis    │
└─────────────────────────────────────┘
```

**Selecciona**: `Graphical install` (primera opción)

---

### Paso 1: Idioma, Ubicación y Teclado

1. **Idioma**:

   - Seleccionar `Español - Spanish` (o tu preferencia)
   - Click "Continuar"

2. **Ubicación**:

   - Seleccionar país (ej: "Colombia", "México", "España")
   - Esto configura zona horaria y repositorios locales
   - Click "Continuar"

3. **Teclado**:

   - Seleccionar distribución de teclado
   - Latinoamericano: `Latinoamericano`
   - España: `Español`
   - Puedes probarlo en la caja de texto
   - Click "Continuar"

---

### Paso 2: Configurar Red

1. **Nombre del equipo (hostname)**:

   - Escribir: `moodle`
   - Este será el nombre que aparece en `moodle.local`
   - Click "Continuar"

2. **Nombre de dominio**:

   - Dejar en blanco o escribir: `local`
   - Click "Continuar"

**Nota**: El instalador intentará obtener IP por DHCP automáticamente.

---

### Paso 3: Usuarios y Contraseñas

1. **Contraseña de root** (administrador):

   - **Opción A (Recomendada para novatos)**: Dejar en blanco
     - Esto desactiva root y da permisos sudo al usuario normal
   - **Opción B**: Establecer contraseña fuerte (ej: `MoodleAdmin2026!`)
   - Click "Continuar"

2. **Crear cuenta de usuario**:

   - Nombre completo: `Profesor Moodle` (o tu nombre)
   - Click "Continuar"

3. **Nombre de usuario**:

   - Escribir: `moodle` (minúsculas, sin espacios)
   - Click "Continuar"

4. **Contraseña de usuario**:

   - Establecer contraseña segura
   - Repetir en la siguiente pantalla
   - Click "Continuar"

---

## 1.4 Particionado del Disco (CRÍTICO para Timeshift)

### Opción A: Particionado Guiado con BTRFS (Recomendado - Más Fácil)

Esta opción es más simple para novatos pero requiere un paso adicional post-instalación.

**Pantalla: "Método de particionado"**

```
┌────────────────────────────────────────────┐
│ ¿Cómo deseas particionar el disco?         │
│                                            │
│  ▸ Guiado - utilizar todo el disco        │
│    Guiado - usar todo el disco con LVM    │
│    Guiado - usar todo el disco con LVM    │
│      cifrado                               │
│    Manual                                  │
└────────────────────────────────────────────┘
```

**Selecciona**: `Guiado - usar todo el disco con LVM cifrado` (tercera opción)

#### ¿Por qué cifrado?

- Protege datos si roban el portátil
- Opcional pero recomendado para instituciones educativas
- Si NO quieres cifrado, usa segunda opción: "Guiado - usar todo el disco con LVM"

**Paso 1.4.1**: Seleccionar disco
```
Seleccione el disco a particionar:
  ▸ SCSI1 (0,0,0) (sda) - 125.0 GB ATA Samsung SSD
```
Click "Continuar"

**Paso 1.4.2**: Esquema de particionado
```
┌────────────────────────────────────────┐
│ Esquema de particionado:               │
│  ▸ Todos los ficheros en una partición│
│    Particiones /home separadas         │
│    Particiones /home, /var, /tmp sep.  │
└────────────────────────────────────────┘
```

**Selecciona**: `Todos los ficheros en una partición` (primera opción)

**Paso 1.4.3**: Confirmar cambios

- Leer resumen de particiones
- Seleccionar "Sí" para escribir cambios
- Click "Continuar"

**Si elegiste cifrado**:

- Aparecerá pantalla: "Sobrescribir datos en discos duros"
- **Recomendado**: Seleccionar "Sí" (tarda 15-30 minutos)
- Puedes cancelar si tienes prisa (menos seguro)
- Establecer **frase de cifrado fuerte** (la necesitarás al arrancar)

**Paso 1.4.4**: CAMBIAR FILESYSTEM A BTRFS (IMPORTANTE)

Antes de continuar con "Finalizar el particionado", necesitas cambiar ext4 a btrfs:

```
┌─────────────────────────────────────────────┐
│ Resumen del particionado:                   │
│                                             │
│ LVM VG debian-vg, LV root - 116.5 GB        │
│   #1  116.5 GB  f  ext4  /                  │
│ LVM VG debian-vg, LV swap_1 - 4.1 GB        │
│   #1    4.1 GB     swap                     │
│                                             │
│ ▸ Finalizar el particionado y escribir...  │
└─────────────────────────────────────────────┘
```

**ANTES de seleccionar "Finalizar"**:

1. **Doble click** en la línea `LVM VG debian-vg, LV root`
2. Aparecerá menú: **Doble click** en `Usar como: Sistema de ficheros ext4 transaccional`
3. Cambiar a: `Sistema de ficheros btrfs transaccional`
4. Click "Listo"
5. **Doble click** nuevamente en `LVM VG debian-vg, LV root`
6. Seleccionar `Opciones de montaje`
7. Marcar estas opciones:

   - ☑ `relatime` - Reduce escrituras al disco
   - ☑ `compress` - Compresión automática (ahorra espacio)
   - ☑ `ssd` - Optimizaciones para SSD
   - ☑ `discard` - TRIM automático para SSD
8. Click "Listo"
9. Ahora SÍ: Seleccionar `▸ Finalizar el particionado y escribir los cambios en el disco`

**Paso 1.4.5**: Confirmación final

- Preguntará: "¿Escribir los cambios en los discos?"
- Seleccionar **Sí**
- Click "Continuar"

Fuente: [Debian Trixie BTRFS Installation Guide](https://mutschler.dev/linux/debian-btrfs-trixie/)

---

### Opción B: Particionado Manual UEFI+GPT (Avanzado)

**Solo para usuarios con experiencia en hardware UEFI.** Permite crear particiones exactas y configurar subvolúmenes BTRFS personalizados.

**Esquema recomendado para UEFI**:

| Partición | Tamaño | Sistema | Punto de montaje | Flags |
|-----------|--------|---------|------------------|-------|
| /dev/sda1 | 512 MB | EFI System Partition | /boot/efi | boot, esp |
| /dev/sda2 | 1 GB | ext4 | /boot | - |
| /dev/sda3 | ~115 GB | **btrfs** | / | - |
| /dev/sda4 | 8 GB | swap | - | swap |

**Opciones de montaje BTRFS para /dev/sda3**:
```
relatime,compress=zstd:3,ssd,discard,space_cache=v2
```

---

### Opción C: Particionado Manual Legacy+MBR (Para BIOS Sin UEFI)

**Para portátiles antiguos sin soporte UEFI** (Phoenix SecureCore, Award BIOS, AMI pre-2010).

El instalador **preguntará** si crear particiones "Primarias" o "Lógicas". Esto es **normal y esperado** en modo Legacy.

**Esquema recomendado para Legacy/MBR**:

| Partición | Tamaño | **Tipo** | Sistema | Punto montaje | Flags |
|-----------|--------|----------|---------|---------------|-------|
| /dev/sda1 | 1 GB | **Primaria** | ext4 | /boot | bootable |
| /dev/sda2 | ~110 GB | **Primaria** | btrfs | / | - |
| /dev/sda3 | 8 GB | **Primaria** | swap | - | swap |

**Diferencias críticas con UEFI**:

❌ **NO crear partición EFI** (`/boot/efi`) - no existe en Legacy\
✅ **Seleccionar PRIMARIA** para todas (no lógicas)\
✅ **Marcar /dev/sda1 como "bootable"** - crítico para arranque\
⚠️ **Límite**: Máximo 4 particiones primarias (usamos 3, suficiente)

**Pasos detallados**:

1. **Crear nueva tabla de particiones**:

   - Tipo: `msdos` (MBR)
   - Confirmar borrado de datos

2. **Partición 1 - /boot**:

   - Tamaño: 1 GB
   - Tipo: **Primaria** ← importante
   - Sistema de archivos: ext4
   - Punto de montaje: `/boot`
   - Flags: **bootable** ← crítico

3. **Partición 2 - raíz**:

   - Tamaño: ~110 GB (resto menos 8GB para swap)
   - Tipo: **Primaria**
   - Sistema de archivos: btrfs
   - Punto de montaje: `/`
   - Opciones de montaje: `relatime,compress=zstd:1,ssd,discard`

4. **Partición 3 - swap**:
   - Tamaño: 8 GB (2x RAM)
   - Tipo: **Primaria**
   - Sistema de archivos: swap
   - Sin punto de montaje

**Importante sobre BTRFS en Legacy**:

- Timeshift funcionará con modo **RSYNC** (no snapshots nativos BTRFS)
- Más lento que UEFI+GPT pero funcional
- Compresión y otras características BTRFS funcionan normalmente

Fuentes:

- [Debian Partitioning Guide](https://www.debian.org/releases/stable/arm64/apcs03.en.html)
- [Debian 13 BTRFS Guide](https://sysguides.com/install-debian-13-with-btrfs)
- [Debian Wiki - Partition](https://wiki.debian.org/Partition)

**Nota sobre swap**:

- 8 GB es 2x tu RAM (permite hibernación)
- Mínimo: 4 GB (1/2 de tu RAM)
- Con BTRFS puedes crear swapfile después si prefieres

---

### ⚠️ NOTA: ¿El Instalador Pregunta "¿Primaria o Lógica?"?

Si durante el particionado manual el instalador te pregunta si crear particiones **"Primarias"** o **"Lógicas"**, hay dos posibilidades:

#### Caso A: Tu BIOS Sí Tiene UEFI (Pero Arrancaste en Legacy)

**Síntomas**: Tu portátil es de 2010 o posterior, pero el instalador pregunta por primarias/lógicas.

**Problema**: Arrancaste en modo Legacy por error (aunque tu hardware soporta UEFI).

**Solución**:

1. Presiona `Ctrl+Alt+Del` para reiniciar
2. Vuelve a **sección 1.2, Paso 3A** y configura UEFI correctamente
3. El instalador ya NO preguntará por primarias/lógicas

#### Caso B: Tu BIOS NO Tiene UEFI (Legacy Nativo)

**Síntomas**:

- Portátil anterior a 2010
- BIOS Phoenix SecureCore, Award, o AMI antiguo
- No encontraste opciones "UEFI", "Boot Mode", "CSM" en ninguna pestaña del BIOS
- El USB aparece como "USB HDD:" (no "UEFI: USB")

**Situación**: Esto es **normal y esperado**. Tu hardware solo soporta Legacy/MBR.

**Solución**:

- Selecciona **PRIMARIA** para todas las particiones
- NO crees partición `/boot/efi` (solo existe en UEFI)
- Sigue el esquema de **Opción C** arriba (Particionado Legacy+MBR)
- Timeshift funcionará con modo RSYNC

Ver **Apéndice B** para más detalles.

---

## 1.5 Selección de Software

Después del particionado, el instalador configurará el sistema base (5-10 minutos).

### Configurar el gestor de paquetes

1. **Analizar otro medio de instalación (CD/DVD)**:

   - Seleccionar **No** (usaremos repositorios en línea)
   - Click "Continuar"

2. **País del servidor de réplica de Debian**:

   - Seleccionar tu país o uno cercano
   - Ejemplo: España, México, Chile, Argentina
   - Click "Continuar"

3. **Servidor de réplica de Debian**:

   - Usar el predeterminado: `deb.debian.org`
   - Click "Continuar"

4. **Información sobre proxy HTTP**:

   - Dejar en blanco (a menos que uses proxy corporativo)
   - Click "Continuar"

5. **Participar en el estudio de uso de paquetes**:

   - Opcional: Seleccionar **No**
   - Click "Continuar"

### Selección de software (MUY IMPORTANTE)

Aparecerá pantalla con lista de entornos de escritorio y utilidades:

```
┌────────────────────────────────────────┐
│ Selección de software:                 │
│                                        │
│ [*] Entorno de escritorio Debian      │
│ [ ] ... GNOME                          │
│ [*] ... XFCE                ← MARCAR  │
│ [ ] ... GNOME Flashback                │
│ [ ] ... KDE Plasma                     │
│ [ ] ... Cinnamon                       │
│ [ ] ... MATE                           │
│ [ ] ... LXDE                           │
│ [ ] ... LXQt                           │
│ [ ] servidor web                       │
│ [ ] servidor de impresión             │
│ [*] servidor SSH                       │
│ [*] utilidades estándar del sistema    │
└────────────────────────────────────────┘
```

**MARCAR** (importante para evitar problemas):

- ☑ `Entorno de escritorio Debian`
- ☑ `... XFCE` ← **CRÍTICO: Marcar este**
- ☑ `servidor SSH`
- ☑ `utilidades estándar del sistema`

**⚠️ CAMBIO IMPORTANTE**: Anteriormente se recomendaba instalar XFCE manualmente después, pero esto causaba problemas con:
- lightdm no arrancando correctamente
- Terminal colgándose
- NetworkManager no configurado

**Instalando XFCE desde el instalador se evitan estos problemas** porque:
- lightdm se configura automáticamente
- NetworkManager viene preconfigurado
- Todas las dependencias se instalan correctamente
- Terminal funciona desde el inicio

Click "Continuar"

El instalador descargará e instalará los paquetes (15-25 minutos dependiendo de tu conexión).

---

## 1.6 Instalar el cargador de arranque GRUB

1. **¿Instalar el cargador de arranque GRUB en su disco duro?**:

   - Seleccionar **Sí**
   - Click "Continuar"

2. **Dispositivo donde instalar el cargador de arranque**:

   - Seleccionar el disco principal (generalmente `/dev/sda`)
   - **NO selecciones una partición** (no debe terminar en número)
   - Correcto: `/dev/sda`
   - Incorrecto: `/dev/sda1`
   - Click "Continuar"

---

## 1.7 Finalizar la Instalación

1. Aparecerá mensaje: **"Instalación completa"**
2. Remover el USB cuando se indique
3. Click "Continuar" para reiniciar

### Primer Arranque

**Si usaste cifrado**:

- Aparecerá pantalla negra pidiendo la frase de cifrado
- Escribir la frase que configuraste
- Presionar `Enter`

**Pantalla de login**:
```
Debian GNU/Linux 13 moodle tty1

moodle login: _
```

- Escribir tu nombre de usuario: `moodle`
- Presionar `Enter`
- Escribir tu contraseña
- Presionar `Enter`

¡Felicidades! Tienes Debian 13 base instalado.

---

## 1.8 Configuración Post-Instalación Básica

### Actualizar el sistema

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas básicas
sudo apt install -y curl wget git nano htop net-tools btrfs-progs
```

## 1.9 Configurar Red con DHCP

```bash
# Verificar nombre de interfaz
ip link show
# Busca algo como: enp0s3, eth0, eno1, etc.
```

```bash
sudo nano /etc/network/interfaces
```

```ini
# /etc/network/interfaces
auto lo
iface lo inet loopback

# Interfaz ethernet - DHCP automático
auto enp0s3
iface enp0s3 inet dhcp
```

---

# PARTE 2: Configuración Post-Instalación de XFCE

**Nota**: Si seguiste las instrucciones de la PARTE 1 y marcaste XFCE en el instalador, ya tienes XFCE funcionando correctamente con lightdm y NetworkManager preconfigurados. Esta sección cubre solo optimizaciones y aplicaciones adicionales.

## 2.1 ¿Por qué XFCE?

Según [Debian Wiki](https://wiki.debian.org/Xfce):
> "XFCE is known for consuming fewer system resources compared to other desktop environments, making it ideal for older computers or systems with limited resources."

**Consumo aproximado:**

- XFCE: ~300-400MB RAM
- GNOME: ~800MB-1GB RAM
- Sin escritorio: ~100-200MB RAM

Con 8GB RAM, XFCE no afectará significativamente el rendimiento de Moodle.

## 2.2 Verificar Instalación

XFCE debería haber arrancado automáticamente después de la instalación. Verifica:

```bash
# Ver si lightdm está corriendo
systemctl status lightdm

# Ver si NetworkManager está activo
systemctl status NetworkManager

# Verificar versión de XFCE
xfce4-about --version
```

Si lightdm no está corriendo:
```bash
sudo systemctl enable lightdm
sudo systemctl start lightdm
```

## 2.3 Aplicaciones Adicionales (Opcionales)

La instalación de XFCE desde el instalador ya incluye: Firefox ESR, Thunar, mousepad, y las utilidades básicas. Solo necesitas instalar complementos adicionales:

```bash
# Plugins para archivos comprimidos en Thunar
sudo apt install -y thunar-archive-plugin file-roller

# Captura de pantalla (si no viene instalado)
sudo apt install -y xfce4-screenshooter

# Visor de PDF
sudo apt install -y evince

# Monitor del sistema gráfico
sudo apt install -y htop
```

## 2.4 Conectar WiFi (Si Es Necesario)

NetworkManager viene preinstalado y configurado. Para conectar WiFi:

**Método Gráfico** (más fácil):
1. Click en el icono de red (panel superior derecho)
2. Selecciona tu red WiFi
3. Ingresa contraseña
4. Conectar

**Método Terminal**:
```bash
# Ver redes disponibles
nmcli device wifi list

# Conectar (reemplaza SSID y contraseña)
nmcli device wifi connect "NombreDeTuWiFi" password "TuContraseña"

# Ver conexiones activas
nmcli connection show --active
```

**Si falta firmware WiFi** (algunas tarjetas lo necesitan):

```bash
# Ver si detecta la tarjeta WiFi
lspci | grep -i network

# Instalar firmwares no-libres
sudo apt install -y firmware-linux-nonfree firmware-iwlwifi firmware-realtek

# Reiniciar para cargar firmwares
sudo reboot
```

**Nota**: Si instalaste con netinst **sin conexión a internet**, es posible que algunos firmwares no se hayan instalado. Conéctate por cable ethernet primero para instalarlos.

## 2.5 Optimizar XFCE para Servidor

```bash
# Desactivar compositor (ahorra recursos)
xfconf-query -c xfwm4 -p /general/use_compositing --create -t bool -s false

# O hacerlo gráficamente:
# Settings → Window Manager Tweaks → Compositor → Desmarcar "Enable display compositing"
```

**Nota**: Al usar `--create`, el parámetro `-t` (tipo) es **obligatorio** y debe ir **después** de `--create`. Los tipos válidos son: `string`, `int`, `uint`, `double`, `bool`, `array`.

## 2.6 Auto-login (Opcional)

Para que inicie sesión automáticamente sin pedir contraseña:

```bash
sudo nano /etc/lightdm/lightdm.conf
```

```ini
[Seat:*]
autologin-user=moodle
autologin-user-timeout=0
```

```bash
# Añadir usuario al grupo autologin
sudo groupadd -r autologin
sudo gpasswd -a moodle autologin
```

---

# PARTE 3: Instalar Timeshift para Snapshots Automáticos

## 3.1 Instalación

```bash
sudo apt install -y timeshift
```

Fuente: [Debian Wiki - Timeshift](https://wiki.debian.org/timeshift)

## 3.2 Configuración Inicial (GUI)

1. Abrir Timeshift desde el menú de aplicaciones
2. **Tipo de snapshot**:

   - **Si usas UEFI+GPT con BTRFS**: Seleccionar **BTRFS** (instantáneo, eficiente)
   - **Si usas Legacy+MBR con BTRFS**: Seleccionar **RSYNC** (el instalador no crea subvolúmenes necesarios)
   - **Si usas ext4**: Seleccionar **RSYNC**

   **⚠️ IMPORTANTE para Legacy/MBR**: Aunque hayas instalado con BTRFS, si estás en modo Legacy (sin UEFI), **debes usar RSYNC**. Si seleccionas BTRFS verás error "El dispositivo de instantánea seleccionado no es un disco de sistema" porque faltan los subvolúmenes `@` y `@home`.

3. **Ubicación**: Seleccionar el disco principal (ej: `/dev/sda`)
4. **Programación** (Schedule):

   - ✅ Boot: 3 snapshots (se crea al encender)
   - ✅ Daily: 5 snapshots
   - ✅ Weekly: 2 snapshots
   - ❌ Hourly: No necesario
   - ❌ Monthly: Opcional

## 3.3 Configuración por CLI (Alternativa)

```bash
# Ver configuración actual
sudo timeshift --list

# Crear snapshot manual
sudo timeshift --create --comments "Antes de actualizar Moodle"

# Configurar via archivo
sudo nano /etc/timeshift/timeshift.json
```

```json
{
  "backup_device_uuid" : "TU-UUID-AQUI",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "true",
  "count_monthly" : "2",
  "count_weekly" : "2",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "3",
  "snapshot_size" : "0",
  "snapshot_count" : "0"
}
```

Para obtener el UUID:
```bash
sudo blkid
```

## 3.4 Snapshots Automáticos Antes de Actualizaciones APT

Instalar hook para apt que crea snapshot antes de cada instalación/actualización:

```bash
# Instalar dependencias necesarias
sudo apt install -y make git

# Clonar repositorio
cd /tmp
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git
cd timeshift-autosnap-apt

# Instalar
sudo make install
```

Ahora, cada vez que ejecutes `apt install`, `apt upgrade` o `apt remove`, se creará un snapshot automáticamente.

Fuente: [GitHub - timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt)

## 3.5 Verificar Snapshots

```bash
# Listar snapshots existentes
sudo timeshift --list

# Ejemplo de salida:
# Num   Name                     Tags  Description
# 0     2024-01-15_10-30-45      B     Boot snapshot
# 1     2024-01-14_03-00-01      D     Daily snapshot
# 2     2024-01-13_03-00-01      D     Daily snapshot
```

## 3.6 Restaurar Sistema (si algo falla)

**Desde XFCE:**

1. Abrir Timeshift desde el menú
2. Seleccionar snapshot deseado
3. Click "Restore"
4. Reiniciar

**Desde consola (si no arranca XFCE):**
```bash
# Listar snapshots
sudo timeshift --list

# Restaurar (interactivo)
sudo timeshift --restore

# Restaurar snapshot específico
sudo timeshift --restore --snapshot '2024-01-15_10-30-45'
```

---

# PARTE 4: Instalar mDNS (Avahi)

## 4.1 Instalación

```bash
sudo apt install -y avahi-daemon avahi-utils
```

## 4.2 Configurar Avahi

```bash
sudo nano /etc/avahi/avahi-daemon.conf
```

```ini
[server]
host-name=moodle
domain-name=local
use-ipv4=yes
use-ipv6=no
allow-interfaces=enp0s3
enable-dbus=yes

[publish]
publish-addresses=yes
publish-hinfo=yes
publish-workstation=no
publish-domain=yes

[reflector]
enable-reflector=no

[rlimits]
rlimit-core=0
rlimit-data=4194304
rlimit-fsize=0
rlimit-nofile=768
rlimit-stack=4194304
rlimit-nproc=3
```

**Nota**: Cambia `enp0s3` por el nombre real de tu interfaz de red (ver con `ip link show`).

## 4.3 Publicar Servicio HTTP

```bash
sudo nano /etc/avahi/services/moodle.service
```

```xml
<?xml version="1.0" standalone='no'?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name>Moodle Server</name>
  <service>
    <type>_http._tcp</type>
    <port>80</port>
    <txt-record>path=/</txt-record>
  </service>
</service-group>
```

## 4.4 Activar Servicio

```bash
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

# Verificar
avahi-resolve -n moodle.local
```

## 4.5 Configurar Hostname

```bash
sudo hostnamectl set-hostname moodle

sudo nano /etc/hosts
```

```
127.0.0.1       localhost
127.0.1.1       moodle.local moodle
```

---

# PARTE 5: Instalar Stack LEMP

## 5.1 Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
```

## 5.2 MariaDB

```bash
sudo apt install -y mariadb-server
sudo systemctl enable mariadb

sudo mysql_secure_installation
```

### Crear Base de Datos

```bash
sudo mysql -u root -p
```

```sql
CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodleuser'@'localhost' IDENTIFIED BY 'TuContraseñaSegura123!';
GRANT ALL PRIVILEGES ON moodle.* TO 'moodleuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 5.3 PHP 8.4

```bash
sudo apt install -y php8.4-fpm php8.4-mysql php8.4-xml php8.4-mbstring php8.4-curl \
  php8.4-zip php8.4-gd php8.4-intl php8.4-soap php8.4-opcache \
  php8.4-redis php8.4-apcu
```

## 5.4 Redis

Redis sirve como caché de sesiones y aplicación, eliminando I/O a disco y mejorando significativamente el rendimiento bajo carga.

```bash
sudo apt install -y redis-server
```

Configurar límite de memoria:

```bash
sudo nano /etc/redis/redis.conf
```

Buscar y descomentar/modificar:

```ini
maxmemory 256mb
maxmemory-policy allkeys-lru
```

```bash
sudo systemctl enable redis-server
sudo systemctl restart redis-server

# Verificar
redis-cli ping
# Respuesta esperada: PONG
```

---

# PARTE 6: Optimización para 12GB RAM

## 6.1 PHP-FPM

```bash
sudo nano /etc/php/8.4/fpm/pool.d/www.conf
```

```ini
pm = dynamic
pm.max_children = 30
pm.start_servers = 8
pm.min_spare_servers = 4
pm.max_spare_servers = 16
pm.max_requests = 500
php_admin_value[memory_limit] = 256M
```

## 6.2 OPcache

```bash
sudo nano /etc/php/8.4/fpm/conf.d/10-opcache.ini
```

```ini
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 32
opcache.max_accelerated_files = 20000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.jit = tracing
opcache.jit_buffer_size = 64M
```

## 6.3 PHP.ini

Aplicar en **ambos** archivos: FPM (para la web) y CLI (para scripts de administración como `upgrade.php`):

```bash
sudo nano /etc/php/8.4/fpm/php.ini
sudo nano /etc/php/8.4/cli/php.ini
```

```ini
upload_max_filesize = 100M
post_max_size = 100M
max_execution_time = 300
max_input_vars = 5000
memory_limit = 256M
```

> **Nota importante**: `max_input_vars` debe ser al menos 5000 en **ambos** php.ini (FPM y CLI). Si solo se configura en FPM, el comando `php admin/cli/upgrade.php` fallará con el error: *"max_input_vars: La configuración de PHP max_input_vars debe ser al menos 5000"*. Verificar con: `php -i | grep max_input_vars`

## 6.4 MariaDB

```bash
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

```ini
[mysqld]
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
innodb_file_per_table = 1
innodb_read_io_threads = 8
innodb_write_io_threads = 8
max_connections = 200
thread_cache_size = 32
table_open_cache = 4000
table_definition_cache = 2000
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
```

```bash
sudo systemctl restart mariadb
```

## 6.5 Kernel

```bash
sudo nano /etc/sysctl.conf
```

```ini
vm.swappiness = 10
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.vfs_cache_pressure = 50
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
```

```bash
sudo sysctl -p
```

---

# PARTE 7: Instalar Moodle

## 7.1 Descargar

```bash
cd /var/www
sudo git clone -b MOODLE_501_STABLE https://github.com/moodle/moodle.git
sudo chown -R www-data:www-data moodle
```

### Instalar Composer y dependencias

Moodle 5.1 requiere las dependencias de Composer para funcionar correctamente. Sin ellas, la interfaz de administración mostrará el aviso "Composer vendor directory not found".

```bash
# Instalar Composer globalmente
sudo php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
sudo rm /tmp/composer-setup.php

# Instalar dependencias de Moodle
sudo -u www-data composer install --no-dev --classmap-authoritative -d /var/www/moodle
```

## 7.2 Directorios

```bash
sudo mkdir -p /var/moodledata /var/cache/moodle
sudo chown www-data:www-data /var/moodledata /var/cache/moodle
sudo chmod 750 /var/moodledata
```

> **Nota**: Las sesiones se almacenan en Redis (ver sección 5.4), no se necesita directorio de sesiones en disco.

## 7.3 Configurar Nginx

```bash
sudo nano /etc/nginx/sites-available/moodle
```

```nginx
server {
    listen 80;
    server_name moodle.local _;

    root /var/www/moodle/public;
    index index.php index.html;

    access_log /var/log/nginx/moodle_access.log;
    error_log /var/log/nginx/moodle_error.log;

    client_max_body_size 100M;

    # Compresión para tablets lentas
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    location / {
        try_files $uri $uri/ /r.php;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 300;
        fastcgi_send_timeout 300;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }

    location ~* \.(engine|inc|install|make|module|profile|po|sh|sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig)?$ {
        deny all;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx php8.4-fpm redis-server
```

## 7.4 Config.php Multi-Red

```bash
sudo nano /var/www/moodle/config.php
```

```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

// Detectar automáticamente la URL
$protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'moodle.local';
$CFG->wwwroot = $protocol . '://' . $host;

$CFG->dataroot = '/var/moodledata';
$CFG->admin = 'admin';
$CFG->directorypermissions = 0750;

$CFG->dbtype = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost = 'localhost';
$CFG->dbname = 'moodle';
$CFG->dbuser = 'moodleuser';
$CFG->dbpass = 'TuContraseñaSegura123!';
$CFG->prefix = 'mdl_';
$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

// Sesiones en Redis (más rápido que archivos)
$CFG->session_handler_class = '\core\session\redis';
$CFG->session_redis_host = '127.0.0.1';
$CFG->session_redis_port = 6379;
$CFG->session_redis_lock_expire = 7200;
$CFG->session_redis_serializer_use_igbinary = false;

$CFG->localcachedir = '/var/cache/moodle';
$CFG->debug = 0;
$CFG->debugdisplay = 0;

require_once(__DIR__ . '/lib/setup.php');
```

## 7.5 Ejecutar Instalador Web

1. Abrir Firefox en XFCE
2. Ir a: `http://localhost`
3. Seguir el asistente de instalación

---

# PARTE 8: Backup Específico de Moodle

Timeshift protege el **sistema**, pero también necesitas backup específico de **datos de Moodle** (base de datos, archivos subidos).

## 8.1 Script de Backup Moodle

```bash
sudo nano /usr/local/bin/moodle-backup.sh
```

```bash
#!/bin/bash
#
# Backup automático de Moodle
# Ejecutar como: sudo moodle-backup.sh
#

set -e

# Configuración
FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/moodle/backups"
MOODLE_DIR="/var/www/moodle"
MOODLE_DATA="/var/moodledata"
DB_NAME="moodle"
DB_USER="moodleuser"
DB_PASS="TuContraseñaSegura123!"
RETENTION_DAYS=30

# Crear directorio si no existe
mkdir -p "$BACKUP_DIR"

echo "========================================"
echo "  BACKUP DE MOODLE - $FECHA"
echo "========================================"

# 1. Poner Moodle en modo mantenimiento
echo "[1/5] Activando modo mantenimiento..."
sudo -u www-data php "$MOODLE_DIR/admin/cli/maintenance.php" --enable

# 2. Backup de base de datos
echo "[2/5] Exportando base de datos..."
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_DIR/db_$FECHA.sql.gz"

# 3. Backup de moodledata
echo "[3/5] Respaldando moodledata..."
tar -czf "$BACKUP_DIR/moodledata_$FECHA.tar.gz" -C /var moodledata

# 4. Backup de config.php
echo "[4/5] Respaldando configuración..."
cp "$MOODLE_DIR/config.php" "$BACKUP_DIR/config_$FECHA.php"

# 5. Desactivar modo mantenimiento
echo "[5/5] Desactivando modo mantenimiento..."
sudo -u www-data php "$MOODLE_DIR/admin/cli/maintenance.php" --disable

# Limpiar backups antiguos
echo "Limpiando backups mayores a $RETENTION_DAYS días..."
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.php" -mtime +$RETENTION_DAYS -delete

# Resumen
echo ""
echo "========================================"
echo "  BACKUP COMPLETADO"
echo "========================================"
echo "Archivos creados:"
ls -lh "$BACKUP_DIR"/*"$FECHA"* 2>/dev/null || echo "Error listando archivos"
echo ""
echo "Espacio usado en backups:"
du -sh "$BACKUP_DIR"
echo "========================================"
```

```bash
sudo chmod +x /usr/local/bin/moodle-backup.sh
```

## 8.2 Programar Backup Automático Diario

```bash
sudo crontab -e
```

```cron
# Backup de Moodle cada día a las 3:00 AM
0 3 * * * /usr/local/bin/moodle-backup.sh >> /var/log/moodle-backup.log 2>&1
```

## 8.3 Cron de Moodle con systemd

Moodle requiere que su cron se ejecute **cada minuto**. En lugar de crontab, usamos un timer de systemd que es más confiable: ejecuta como `www-data`, previene ejecuciones simultáneas y permite mejor logging con `journalctl`.

```bash
sudo nano /etc/systemd/system/moodle-cron.service
```

```ini
[Unit]
Description=Moodle Cron
After=network.target mariadb.service redis-server.service php8.4-fpm.service

[Service]
Type=oneshot
User=www-data
Group=www-data
ExecStart=/usr/bin/php8.4 /var/www/moodle/admin/cli/cron.php
StandardOutput=null
```

```bash
sudo nano /etc/systemd/system/moodle-cron.timer
```

```ini
[Unit]
Description=Ejecutar Moodle Cron cada minuto

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
```

Activar el timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now moodle-cron.timer
```

Verificar que esté funcionando:

```bash
sudo systemctl status moodle-cron.timer
sudo journalctl -u moodle-cron --since "5 minutes ago"
```

## 8.4 Script de Restauración Moodle

```bash
sudo nano /usr/local/bin/moodle-restore.sh
```

```bash
#!/bin/bash
#
# Restaurar Moodle desde backup
# Uso: sudo moodle-restore.sh <fecha>
# Ejemplo: sudo moodle-restore.sh 20240115_030001
#

if [ -z "$1" ]; then
    echo "Uso: $0 <fecha_backup>"
    echo ""
    echo "Backups disponibles:"
    ls -1 /home/moodle/backups/db_*.sql.gz | sed 's/.*db_\(.*\)\.sql\.gz/\1/'
    exit 1
fi

FECHA=$1
BACKUP_DIR="/home/moodle/backups"
DB_NAME="moodle"
DB_USER="moodleuser"
DB_PASS="TuContraseñaSegura123!"

# Verificar que existen los archivos
if [ ! -f "$BACKUP_DIR/db_$FECHA.sql.gz" ]; then
    echo "Error: No existe backup de fecha $FECHA"
    exit 1
fi

echo "¿Restaurar backup del $FECHA? Esto sobrescribirá los datos actuales."
read -p "Escribir 'SI' para confirmar: " confirm

if [ "$confirm" != "SI" ]; then
    echo "Cancelado."
    exit 0
fi

echo "[1/4] Activando modo mantenimiento..."
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --enable

echo "[2/4] Restaurando base de datos..."
gunzip < "$BACKUP_DIR/db_$FECHA.sql.gz" | mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"

echo "[3/4] Restaurando moodledata..."
rm -rf /var/moodledata/*
tar -xzf "$BACKUP_DIR/moodledata_$FECHA.tar.gz" -C /var
chown -R www-data:www-data /var/moodledata

echo "[4/4] Desactivando modo mantenimiento..."
sudo -u www-data php /var/www/moodle/admin/cli/maintenance.php --disable

echo ""
echo "Restauración completada exitosamente."
```

```bash
sudo chmod +x /usr/local/bin/moodle-restore.sh
```

## 8.5 Repositorio remoto en GitHub

Subir la documentación y configuración del proyecto a GitHub como respaldo adicional.

### Configurar identidad de Git

```bash
git config --global user.name "alvaretto"
git config --global user.email "alvaroangelm@gmail.com"
```

### Generar clave SSH

```bash
ssh-keygen -t ed25519 -C "alvaretto@moodle.local" -f ~/.ssh/id_ed25519 -N ""
```

Copiar la clave pública:

```bash
cat ~/.ssh/id_ed25519.pub
```

Agregar la clave en GitHub:

1. Ir a https://github.com/settings/keys
2. Clic en **New SSH key**
3. Título: `moodle-server`
4. Pegar la clave pública
5. Clic en **Add SSH key**

### Configurar .gitignore

El archivo `.gitignore` evita subir archivos sensibles o innecesarios al repositorio:

```
.claude/
datos-sensibles/
```

La carpeta `datos-sensibles/` contiene archivos con información privada (contraseñas, datos de estudiantes, etc.) que nunca deben subirse a GitHub.

### Configurar remoto y subir

```bash
cd ~/Proyectos/MoodleDebian
git remote add origin git@github.com:alvaretto/moodle-debian.git
git push -u origin master
```

---

# PARTE 9: Optimización para Tablets Windows 10

## 9.1 Tema Ligero

En Moodle: **Site administration → Appearance → Themes**
- Usar tema **Boost** (predeterminado) - es el más ligero

## 9.2 Configuraciones para Conexiones Lentas

**Site administration → Server → Performance:**

- Theme designer mode: OFF
- Cache JavaScript: ON
- Cache templates: ON

**Site administration → Plugins → Filters:**

- Desactivar filtros no usados
- Mantener solo: MathJax (para fórmulas de R-exams)

## 9.3 Bloques a Evitar

Eliminar de los cursos:

- Recent Activity (muy pesado)
- Online Users (polling constante)
- Chat (consume recursos)

---

# PARTE 10: Plugins de Formato de Curso

Los formatos de curso estándar de Moodle (Topics, Weekly) muestran todas las secciones en una sola página con scroll. Para tablets y cursos con muchas secciones, conviene usar formatos con **pestañas** que organizan el contenido de forma más navegable.

## 10.1 Onetopic (format_onetopic)

Muestra cada sección del curso como una **pestaña** en la parte superior. Al entrar a una actividad y volver, regresa a la pestaña correcta. Es el formato con pestañas más popular de Moodle (+9.800 sitios).

- **Autor**: David Herney Bernal García
- **Repositorio**: https://github.com/davidherney/moodle-format_onetopic
- **Plugin directory**: https://moodle.org/plugins/format_onetopic

### Instalación

```bash
cd /var/www/moodle/course/format
sudo git clone https://github.com/davidherney/moodle-format_onetopic.git onetopic
sudo chown -R www-data:www-data onetopic
```

## 10.2 Multitopic (format_multitopic)

Similar a Onetopic pero con secciones **colapsables** dentro de cada pestaña y una jerarquía más clara de sub-temas. Útil cuando un tema tiene muchas actividades que conviene agrupar.

- **Autor**: James Calder (Otago Polytechnic)
- **Repositorio**: https://github.com/james-cnz/moodle-format_multitopic
- **Plugin directory**: https://moodle.org/plugins/format_multitopic

### Instalación

```bash
cd /var/www/moodle/course/format
sudo git clone -b v5.0.1 --depth 1 https://github.com/james-cnz/moodle-format_multitopic.git multitopic
sudo chown -R www-data:www-data multitopic
```

## 10.3 Ejecutar actualización

Después de copiar cualquier plugin, ejecutar la actualización de Moodle para registrarlo en la base de datos:

```bash
sudo -u www-data php /var/www/moodle/admin/cli/upgrade.php
```

Confirmar con `s` cuando pregunte. La salida debe mostrar `++ Éxito ++` para cada plugin nuevo.

## 10.4 Activar en un curso

1. Entrar al curso como administrador
2. **Configuración del curso** (icono de engranaje)
3. En **Formato de curso**, seleccionar **Onetopic format** o **Multitopic format**
4. Guardar cambios

Cada sección aparecerá como una pestaña en la parte superior del curso.

## 10.5 Comparación

| Característica | Onetopic | Multitopic |
|----------------|----------|------------|
| Pestañas | Si | Si |
| Sub-pestañas | Si (menos obvio) | Si (jerarquía clara) |
| Secciones colapsables | No | Si |
| Secciones temporizadas | No | Si |
| Popularidad | +9.800 sitios | Menor adopción |

---

# PARTE 11: Importar Ejercicios R-exams

## 11.1 Generar XML en R

```r
library(exams)

exams2moodle(
  file = c("ejercicio1.Rmd", "ejercicio2.Rmd"),
  n = 50,
  name = "Matematicas-ICFES",
  dir = "output",
  edir = "ejercicios"
)
```

## 11.2 Importar en Moodle

1. **Site administration → Question bank → Import**
2. Formato: **Moodle XML format**
3. Subir archivo generado
4. Crear Quiz con las preguntas importadas

## 11.3 Configuración de Quiz para 100 Estudiantes

```
Timing:
  - Time limit: según necesidad
  - When time expires: Submit automatically

Layout:
  - New page: Every question (reduce carga por página)
  - Navigation method: Sequential

Question behaviour:
  - Shuffle within questions: Yes
  - How questions behave: Deferred feedback
```

---

# PARTE 12: Panel de Control en Escritorio XFCE

## 12.1 Script de Estado del Sistema

```bash
sudo nano /usr/local/bin/moodle-status.sh
```

```bash
#!/bin/bash

clear
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           ESTADO DEL SERVIDOR MOODLE                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# IP actual
echo "📍 DIRECCIÓN DE ACCESO:"
IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
echo "   http://moodle.local"
echo "   http://$IP"
echo ""

# Servicios
echo "⚙️  SERVICIOS:"
for svc in nginx php8.4-fpm mariadb redis-server avahi-daemon; do
    status=$(systemctl is-active $svc 2>/dev/null)
    if [ "$status" = "active" ]; then
        echo "   ✅ $svc"
    else
        echo "   ❌ $svc: $status"
    fi
done
echo ""

# Recursos
echo "💾 RECURSOS:"
echo "   RAM: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "   Disco: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 " usado)"}')"
echo "   CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% usado"
echo ""

# Snapshots
echo "📸 ÚLTIMOS SNAPSHOTS (Timeshift):"
sudo timeshift --list 2>/dev/null | grep -E "^[0-9]" | head -3 || echo "   No hay snapshots"
echo ""

# Backups Moodle
echo "💿 ÚLTIMOS BACKUPS MOODLE:"
ls -lht /home/moodle/backups/*.gz 2>/dev/null | head -3 | awk '{print "   " $9 " (" $5 ")"}' || echo "   No hay backups"
echo ""

echo "════════════════════════════════════════════════════════════"
```

```bash
sudo chmod +x /usr/local/bin/moodle-status.sh
```

## 12.2 Crear Accesos Directos en Escritorio

```bash
# Crear directorio Desktop si no existe
mkdir -p ~/Desktop

# Estado del servidor
cat > ~/Desktop/estado-moodle.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Estado Moodle
Comment=Ver estado del servidor
Exec=xfce4-terminal -e "bash -c '/usr/local/bin/moodle-status.sh; read -p \"Presiona Enter...\"'"
Icon=utilities-system-monitor
Terminal=false
Categories=System;
EOF

# Abrir Moodle en navegador
cat > ~/Desktop/abrir-moodle.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Abrir Moodle
Comment=Abrir Moodle en el navegador
Exec=firefox-esr http://localhost
Icon=firefox-esr
Terminal=false
Categories=Network;
EOF

# Timeshift (Snapshots)
cat > ~/Desktop/timeshift.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Timeshift Snapshots
Comment=Crear y restaurar snapshots del sistema
Exec=pkexec timeshift-gtk
Icon=timeshift
Terminal=false
Categories=System;
EOF

# Backup Moodle
cat > ~/Desktop/backup-moodle.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Backup Moodle
Comment=Crear backup de datos de Moodle
Exec=xfce4-terminal -e "bash -c 'sudo /usr/local/bin/moodle-backup.sh; read -p \"Presiona Enter...\"'"
Icon=drive-harddisk
Terminal=false
Categories=System;
EOF

# Restaurar Moodle
cat > ~/Desktop/restaurar-moodle.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Restaurar Moodle
Comment=Restaurar Moodle desde backup
Exec=xfce4-terminal -e "bash -c 'sudo /usr/local/bin/moodle-restore.sh; read -p \"Presiona Enter...\"'"
Icon=edit-undo
Terminal=false
Categories=System;
EOF

# Hacer ejecutables
chmod +x ~/Desktop/*.desktop
```

## 12.3 Resultado en Escritorio

Tendrás estos iconos en el escritorio:

| Icono | Función |
|-------|---------|
| 🖥️ Estado Moodle | Ver IP, servicios, recursos, snapshots |
| 🌐 Abrir Moodle | Abre Moodle en Firefox |
| 📸 Timeshift | Crear/restaurar snapshots del sistema |
| 💾 Backup Moodle | Backup manual de base de datos y archivos |
| ↩️ Restaurar Moodle | Restaurar desde backup anterior |

---

# PARTE 13: Uso Diario

## 13.1 En Casa (Preparación)

1. Encender portátil → inicia XFCE automáticamente
2. Click en **"Abrir Moodle"** en escritorio
3. Preparar exámenes, importar preguntas XML de R-exams
4. **Antes de transportar**: Click en **"Backup Moodle"**

## 13.2 En el Aula

1. Conectar cable RJ45 al router del aula
2. Encender portátil
3. Click en **"Estado Moodle"** para verificar IP y servicios
4. Indicar a estudiantes: **`http://moodle.local`**

## 13.3 Matriculación Masiva de Estudiantes

Para registrar muchos estudiantes de una vez: **Administración del sitio → Usuarios → Subir usuarios**.

### Formato del archivo CSV

Columnas mínimas requeridas:

| Columna | Descripción | Ejemplo |
|---------|-------------|---------|
| `username` | Nombre de usuario (único) | `est01` |
| `password` | Contraseña | `Clave123!` |
| `firstname` | Nombre | `Juan` |
| `lastname` | Apellido | `Pérez` |
| `email` | Correo electrónico | `est01@mail.com` |

Para matricular directamente en un curso, agregar:

| Columna | Descripción | Ejemplo |
|---------|-------------|---------|
| `course1` | Nombre corto del curso | `icfes-math` |
| `role1` | Rol en el curso | `student` |

### Ejemplo de CSV

```csv
username,password,firstname,lastname,email,course1,role1
est01,Clave123!,Juan,Pérez,est01@mail.com,icfes-math,student
est02,Clave123!,María,López,est02@mail.com,icfes-math,student
est03,Clave123!,Carlos,Gómez,est03@mail.com,icfes-math,student
```

> **Nota**: Las contraseñas deben cumplir la política configurada en **Administración del sitio → Seguridad → Normas del sitio**.

## 13.4 Campos Personalizados de Perfil (Datos de Contacto)

Para recopilar datos adicionales de los estudiantes (celular, datos del acudiente), crear campos personalizados en:

**Administración del sitio → Usuarios → Campos de perfil de usuario**

### Crear categoría

Primero crear una categoría para agrupar los campos:

1. Clic en **"Crear una nueva categoría de perfil"**
2. Nombre: `Datos de contacto`
3. Guardar

### Crear campos

Dentro de la categoría "Datos de contacto", crear 3 campos de tipo **Entrada de texto**:

| Campo | Nombre corto | Obligatorio | Visible | Editable |
|-------|-------------|-------------|---------|----------|
| Celular del estudiante | `celular` | Sí | Sí | Sí |
| Nombre del acudiente | `acudiente_nombre` | Sí | Sí | Sí |
| Celular del acudiente | `acudiente_celular` | Sí | Sí | Sí |

Para cada campo:

1. Clic en **"Crear un nuevo campo de perfil"** → **Entrada de texto**
2. Nombre: (según la tabla)
3. Nombre corto: (según la tabla)
4. **¿Es este campo obligatorio?**: Sí
5. **¿Visible para quién?**: Visible para el usuario
6. **¿Editable por el usuario?**: Sí
7. **¿Mostrar en la página de registro?**: Sí
8. Guardar

Los estudiantes verán estos campos al editar su perfil o al registrarse.

## 13.5 Restringir Edición de Perfil del Estudiante

El estudiante solo debe poder editar los campos personalizados ("Otros campos"). Los datos básicos los asigna el profesor y el resto del formulario se oculta.

### Paso 1: Bloquear campos vía autenticación

**Administración del sitio → Extensiones → Autenticación → Cuentas manuales**

Cambiar a **Bloqueado** los siguientes campos:

| Campo | Estado |
|-------|--------|
| Nombre | Bloqueado |
| Apellido(s) | Bloqueado |
| Dirección de correo | Bloqueado |
| Ciudad/Pueblo | Bloqueado |
| País | Bloqueado |
| Institución | Bloqueado |
| Departamento | Bloqueado |

Guardar cambios. Estos campos aparecerán visibles pero en gris (no editables) en el perfil del estudiante.

### Paso 2: Ocultar campos innecesarios con CSS

**Administración del sitio → Apariencia → HTML adicional → Dentro de HEAD**

Pegar el siguiente bloque CSS. Solo afecta la página de edición de perfil del estudiante (`/user/edit.php`), no afecta la vista del administrador:

```html
<style>
/* === Perfil del estudiante: ocultar campos innecesarios === */

/* Campos dentro de General */
#page-user-edit #fitem_id_moodlenetprofile,
#page-user-edit #fitem_id_timezone,
#page-user-edit #fitem_id_description_editor,
#page-user-edit [data-groupname="description_editor"],

/* Sección: Imagen del usuario */
#page-user-edit #id_moodle_picture,

/* Sección: Nombres adicionales */
#page-user-edit #id_moodle_additional,

/* Sección: Intereses */
#page-user-edit #id_moodle_interests,

/* Campos dentro de Opcional */
#page-user-edit #fitem_id_idnumber,
#page-user-edit #fitem_id_phone1,
#page-user-edit #fitem_id_phone2,
#page-user-edit #fitem_id_address {
    display: none !important;
}

/* Visibilidad del correo: solo lectura */
#page-user-edit #fitem_id_maildisplay select {
    pointer-events: none;
    opacity: 0.7;
}

/* === Preferencias: ocultar todo excepto Editar perfil === */
#page-user-preferences a[href*="change_password"],
#page-user-preferences a[href*="language"],
#page-user-preferences a[href*="forum"],
#page-user-preferences a[href*="editor"],
#page-user-preferences a[href*="calendar"],
#page-user-preferences a[href*="contentbank"],
#page-user-preferences a[href*="message"],
#page-user-preferences a[href*="notification"] {
    display: none !important;
}
</style>
```

### Paso 3: Ocultar correo electrónico entre estudiantes

Forzar que el correo no sea visible para otros estudiantes:

```bash
sudo -u www-data php /var/www/moodle/admin/cli/cfg.php --name=defaultpreference_maildisplay --set=0
```

Para aplicarlo a usuarios existentes:

```bash
sudo -u www-data php -r "
define('CLI_SCRIPT', true);
require('/var/www/moodle/config.php');
global \$DB;
\$DB->set_field('user', 'maildisplay', 0, []);
"
```

> `maildisplay = 0` significa "Solo los administradores pueden ver mi correo".

### Paso 4: Desactivar blogs e insignias

Estas funcionalidades no se usan en el servidor portátil. Desactivarlas elimina sus secciones de la página de Preferencias:

```bash
sudo -u www-data php /var/www/moodle/admin/cli/cfg.php --name=enableblogs --set=0
sudo -u www-data php /var/www/moodle/admin/cli/cfg.php --name=enablebadges --set=0
```

### Paso 5: Ocultar lista de Participantes a estudiantes

Impedir que los estudiantes vean la pestaña "Participantes" del curso, prohibiendo la capacidad a nivel de sistema:

```bash
sudo -u www-data php -r "
define('CLI_SCRIPT', true);
require('/var/www/moodle/config.php');
require_once(\$CFG->libdir . '/accesslib.php');

\$studentrole = \$DB->get_record('role', ['shortname' => 'student']);
\$context = context_system::instance();
assign_capability('moodle/course:viewparticipants', CAP_PROHIBIT, \$studentrole->id, \$context->id, true);
"
sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php
```

> `CAP_PROHIBIT` garantiza que no se pueda sobrescribir en ningún contexto inferior (curso, categoría).

### Paso 6: Desactivar acceso de invitados

Impedir completamente el acceso como invitado al sitio y a todos los cursos:

```bash
# Ocultar botón "Acceder como invitado" de la página de login
sudo -u www-data php /var/www/moodle/admin/cli/cfg.php --name=guestloginbutton --set=0

# Desactivar auto-login de invitados
sudo -u www-data php /var/www/moodle/admin/cli/cfg.php --name=autologinguests --set=0

# Desactivar matriculación de invitados en todos los cursos existentes
sudo -u www-data php -r "
define('CLI_SCRIPT', true);
require('/var/www/moodle/config.php');
global \$DB;
\$DB->set_field('enrol', 'status', 1, ['enrol' => 'guest']);
"
```

### Paso 7: Desactivar auto-matriculación

**Administración del sitio → Extensiones → Matriculaciones → Gestionar plugins de matriculación**

1. Buscar **Auto-matriculación**
2. Clic en el icono del **ojo** para desactivarla
3. Solo el profesor matricula estudiantes (manualmente o por CSV)

### Resultado

El formulario de edición de perfil del estudiante mostrará:

| Sección | Campos visibles | Editable |
|---------|----------------|----------|
| General | Nombre, Apellido(s), Correo, Visibilidad correo, Ciudad, País | No (bloqueados) |
| Opcional | Institución, Departamento | No (bloqueados) |
| Otros campos | Celular, Nombre acudiente, Celular acudiente | Sí |

## 13.6 Si Algo Falla

**Problema menor (Moodle no funciona):**

1. Click en **"Restaurar Moodle"**
2. Seleccionar backup reciente

**Problema grave (sistema no arranca bien):**

1. Click en **"Timeshift Snapshots"**
2. Seleccionar snapshot anterior
3. Restaurar y reiniciar

---

# Resumen de Protección de Datos

| Nivel | Herramienta | Frecuencia | Qué Protege |
|-------|-------------|------------|-------------|
| **Sistema completo** | Timeshift | Boot + Diario | SO, configuraciones, aplicaciones |
| **Antes de apt** | timeshift-autosnap | Cada actualización | Evita problemas por actualizaciones |
| **Datos Moodle** | moodle-backup.sh | Diario 3AM | Base de datos, archivos subidos |
| **Manual** | Iconos escritorio | Cuando quieras | Backup/Restore bajo demanda |

---

# Resumen de Acceso

| Ubicación | Conexión | URL de Acceso |
|-----------|----------|---------------|
| Portátil (local) | - | `http://localhost` |
| Casa profesor (otro dispositivo) | WiFi/LAN | `http://moodle.local` |
| Aula (tablets estudiantes) | WiFi | `http://moodle.local` |
| Emergencia (si .local falla) | Cualquiera | `http://[IP-del-servidor]` |

---

# Fuentes

## Documentación Oficial Debian 13

- [Debian 13.3 Release Notes](https://www.debian.org/News/2026/20260110) - Notas de lanzamiento actualizadas a enero 2026
- [Debian Trixie Installation Manual](https://www.debian.org/releases/trixie/installmanual) - Guía oficial de instalación
- [Debian Download](https://www.debian.org/download) - Descarga oficial netinst ISO
- [Debian GNU/Linux Installation Guide (PDF)](https://d-i.debian.org/manual/en.armhf/install.en.pdf) - Manual completo en PDF

## Particionado y BTRFS

- [Debian Recommended Partitioning Scheme](https://www.debian.org/releases/stable/arm64/apcs03.en.html) - Esquemas oficiales
- [Debian Wiki - Partition](https://wiki.debian.org/Partition) - Guía completa de particionado
- [Debian Trixie BTRFS Installation Guide](https://mutschler.dev/linux/debian-btrfs-trixie/) - Tutorial BTRFS actualizado diciembre 2025
- [Install Debian 13 with Btrfs Snapshots](https://sysguides.com/install-debian-13-with-btrfs) - Guía completa con snapshots (octubre 2025)
- [Installing Debian with BTRFS and Snapper](https://medium.com/@inatagan/installing-debian-with-btrfs-snapper-backups-and-grub-btrfs-27212644175f) - Configuración avanzada (agosto 2025)

## Sistema y Herramientas

- [Debian Wiki - Timeshift](https://wiki.debian.org/timeshift) - Snapshots automáticos
- [GitHub - timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) - Snapshots pre-actualización
- [LinuxBuzz - Timeshift on Debian](https://www.linuxbuzz.com/how-to-install-use-timeshift-on-debian/)
- [GitHub - Debian-Xfce4-Minimal-Install](https://github.com/coonrad/Debian-Xfce4-Minimal-Install)
- [Debian Wiki - XFCE](https://wiki.debian.org/Xfce)
- [ArchWiki - Avahi](https://wiki.archlinux.org/title/Avahi)

## Moodle

- [MoodleDocs - Performance](https://docs.moodle.org/501/en/Performance_recommendations)
- [R-exams - E-Learning Tutorial](https://www.r-exams.org/tutorials/elearning/)

---

# APÉNDICE A: Glosario para Novatos

## Términos de Instalación

| Término | Significado | ¿Para qué sirve? |
|---------|-------------|------------------|
| **ISO** | Archivo de imagen de disco | Contiene todo el sistema operativo para instalar |
| **netinst** | Network Install - Instalación por red | ISO pequeña que descarga paquetes durante instalación |
| **USB booteable** | USB que arranca el instalador | Permite instalar el sistema sin CD/DVD |
| **BIOS/UEFI** | Firmware del ordenador | Controla el arranque antes del sistema operativo |
| **Boot Menu** | Menú de arranque | Permite elegir desde qué dispositivo arrancar (USB, disco, etc.) |

## Modos de Arranque (IMPORTANTE)

| Término | Tabla Particiones | Año | Estado | Ventajas | Desventajas |
|---------|-------------------|-----|--------|----------|-------------|
| **UEFI** | GPT | 2010+ | ✅ Moderno (usar este) | Ilimitadas particiones, discos >2TB, arranque rápido | Ninguna |
| **Legacy/BIOS** | MBR/DOS | 1981-2010 | ⚠️ Obsoleto | Compatible con PCs muy antiguos | Máx 4 particiones primarias, límite 2TB |
| **CSM** | Ambas | - | ⚠️ Modo compatibilidad | Permite Legacy en hardware UEFI | Confuso, desactivar |

**Cómo identificar**:

- Durante particionado, si pregunta "¿Primaria o Lógica?" → Estás en **Legacy** (malo)
- Si crea partición EFI automáticamente → Estás en **UEFI** (bueno)

## Sistemas de Archivos

| Término | Significado | Ventajas | Desventajas |
|---------|-------------|----------|-------------|
| **ext4** | Extended File System 4 | Estable, maduro, compatible | No tiene snapshots nativos |
| **BTRFS** | B-Tree File System | Snapshots instantáneos, compresión, auto-reparación | Más nuevo, consume más RAM |
| **swap** | Memoria de intercambio | Permite hibernación, evita crashes por falta de RAM | Ocupa espacio en disco |
| **FAT32** | File Allocation Table 32 | Compatible con UEFI para boot | Limitado, no usar para sistema |

## Particionado y Tablas de Particiones

| Término | Significado | Ejemplo / Contexto |
|---------|-------------|-------------------|
| **/dev/sda** | Primer disco SATA | Todo el disco SSD de 125GB |
| **/dev/sda1** | Primera partición del disco | Partición EFI de 512MB (en UEFI) |
| **/dev/sda2** | Segunda partición | /boot de 1GB |
| **GPT** | GUID Partition Table | Tabla moderna usada con UEFI (hasta 128 particiones) |
| **MBR** | Master Boot Record | Tabla antigua usada con Legacy (máx 4 primarias) |
| **Partición Primaria** | Partición principal en MBR | Solo en Legacy/MBR, máximo 4 |
| **Partición Lógica** | Partición dentro de extendida | Solo en Legacy/MBR, ilimitadas dentro de extendida |
| **LVM** | Logical Volume Manager | Permite redimensionar particiones fácilmente |
| **Cifrado (LUKS)** | Linux Unified Key Setup | Encripta el disco con contraseña |

**Nota**: En UEFI+GPT no existen particiones "primarias" ni "lógicas", todas son del mismo tipo.

## Puntos de Montaje

| Ruta | Descripción | Contenido típico |
|------|-------------|------------------|
| **/** | Raíz del sistema | Todo el sistema operativo |
| **/boot** | Archivos de arranque | Kernel de Linux, initramfs |
| **/boot/efi** | Partición EFI | Cargador de arranque UEFI |
| **/home** | Carpetas de usuarios | Documentos, descargas, configuraciones personales |
| **/var** | Datos variables | Logs, caché, bases de datos |
| **/tmp** | Archivos temporales | Se borran al reiniciar |

## Red y Servicios

| Término | Significado | Ejemplo |
|---------|-------------|---------|
| **hostname** | Nombre del equipo | `moodle` |
| **FQDN** | Fully Qualified Domain Name | `moodle.local` |
| **DHCP** | Asigna IPs automáticamente | Router da IP al portátil automáticamente |
| **IP estática** | IP fija manualmente | `192.168.1.50` (no cambia nunca) |
| **mDNS** | Multicast DNS | Permite usar `moodle.local` en vez de IP |
| **Avahi** | Implementación mDNS en Linux | Hace que funcione `moodle.local` |

## Comandos Básicos

| Comando | Qué hace | Ejemplo |
|---------|----------|---------|
| `sudo` | Ejecutar como administrador | `sudo apt update` |
| `apt update` | Actualizar lista de paquetes | Debe hacerse antes de `apt upgrade` |
| `apt upgrade` | Actualizar paquetes instalados | Instala nuevas versiones |
| `apt install` | Instalar software | `apt install firefox` |
| `systemctl start` | Iniciar un servicio | `systemctl start nginx` |
| `systemctl enable` | Arrancar servicio al inicio | `systemctl enable nginx` |
| `nano` | Editor de texto simple | `nano archivo.txt` |

---

# APÉNDICE B: Solución de Problemas Comunes

## Durante la Instalación

### ⚠️ IMPORTANTE: No Instalar XFCE Manualmente

**Problema común**: Instalar el sistema base sin escritorio y después instalar XFCE manualmente puede causar:
- lightdm que no arranca (pantalla negra o solo terminal)
- Terminal XFCE que se cuelga al abrir
- NetworkManager no configurado correctamente
- Falta de integración entre componentes

**Solución**: Durante la instalación de Debian, en "Selección de software", **MARCA XFCE directamente**. Esto asegura que lightdm, NetworkManager y todas las dependencias se configuren correctamente desde el inicio.

Ver: **PARTE 1, Sección 1.5 - Selección de software**

---

### El instalador pregunta "¿Partición Primaria o Lógica?"

**Síntomas**: Durante el particionado manual aparece pregunta sobre tipo de partición

**Causa**: El portátil arrancó en modo **Legacy/BIOS** en vez de UEFI

**Impacto**:

- Usarás tabla MBR (obsoleta, límite 2TB)
- Solo 4 particiones primarias posibles
- Problemas potenciales con BTRFS snapshots

**Solución (RECOMENDADA)**:

1. Presionar `Ctrl+Alt+Del` para reiniciar
2. Al arrancar, entrar al BIOS/UEFI (ver sección 1.2)
3. Cambiar **Boot Mode** de `Legacy` a **`UEFI`**
4. Desactivar **CSM** (Compatibility Support Module)
5. En Boot Order, seleccionar **`UEFI: [nombre USB]`** (no "USB HDD:")
6. Guardar (F10) y reiniciar
7. El instalador ya NO preguntará por primarias/lógicas

**Solución alternativa (NO recomendada)**:

Si no puedes activar UEFI (portátil muy antiguo):
- Selecciona **PRIMARIA** para las 3 particiones (/boot, /, swap)
- NO creates partición EFI (solo existe en UEFI)
- Esquema: `/dev/sda1` (boot, 1GB, ext4) + `/dev/sda2` (/, 112GB, btrfs) + `/dev/sda3` (swap, 8GB)

---

### El instalador no detecta la red

**Síntomas**: Mensaje "No se detectó ninguna interfaz de red"

**Soluciones**:

1. Conectar cable ethernet (RJ45) directamente al router
2. Si usas WiFi, el instalador netinst puede no tener drivers
   - Descargar ISO completa con firmware: `debian-13.3.0-amd64-DVD-1.iso`
   - O instalar sin red y configurar WiFi después

### El USB no arranca

**Síntomas**: El PC arranca normalmente sin mostrar el instalador

**Soluciones**:

1. Verificar que creaste el USB correctamente (no simplemente copiar el .iso)
2. Probar otra tecla para acceder al Boot Menu (F2, F10, F12, Del, Esc)
3. Desactivar "Secure Boot" en BIOS/UEFI
4. Cambiar de Legacy/BIOS a UEFI (o viceversa)

### Error "Fallo al crear la partición"

**Síntomas**: El particionado falla con errores

**Soluciones**:

1. El disco puede tener particiones GPT/MBR mixtas
2. En el menú del instalador, ir a: Shell → `wipefs -a /dev/sda` → Reintentar
3. Usar particionado manual y eliminar todas las particiones primero

## Después de la Instalación

### No puedo acceder a `moodle.local`

**Desde las tablets**:

1. Verificar que Avahi está corriendo: `systemctl status avahi-daemon`
2. Probar con la IP directamente: `ip addr show` para ver IP
3. Verificar que tablets están en la misma red WiFi
4. Windows 10 antiguo puede necesitar actualización

**Desde el propio servidor**:

- Editar `/etc/hosts` y añadir línea: `127.0.1.1 moodle.local`

### Timeshift: Error "no es un disco de sistema"

**Síntomas**:
- Al abrir Timeshift y seleccionar tipo BTRFS aparece: "El dispositivo de instantánea seleccionado no es un disco de sistema"
- Solo tienes un disco pero Timeshift no lo reconoce

**Causa**:
- Instalaste en modo **Legacy/MBR** con BTRFS
- El instalador de Debian en Legacy **no crea** los subvolúmenes BTRFS que Timeshift necesita (`@` y `@home`)
- Timeshift detecta BTRFS pero no encuentra la estructura de subvolúmenes requerida

**Solución FÁCIL (Recomendada)**:
1. Abrir Timeshift: `sudo timeshift-gtk`
2. En "Tipo de snapshot", seleccionar **RSYNC** (no BTRFS)
3. Seleccionar tu disco `/dev/sda`
4. Configurar programación y continuar
5. Los snapshots funcionarán correctamente (solo serán más lentos)

**Solución COMPLEJA (No recomendada)**:
Crear manualmente los subvolúmenes BTRFS siguiendo [esta guía](https://mutschler.dev/linux/debian-btrfs-trixie/). Requiere:
- Arrancar en modo recovery o live USB
- Recrear estructura de subvolúmenes
- Modificar `/etc/fstab`
- Reinstalar GRUB
- Riesgo de pérdida de datos si se hace mal

**Diferencia práctica**:
- RSYNC: Snapshot tarda 5-10 minutos, ocupa más espacio
- BTRFS: Snapshot instantáneo, ahorra espacio
- Ambos restauran el sistema correctamente

### Error "permisos no válidos al tratar de crear un directorio" en Extensiones

**Síntomas**:
- Al entrar a **Administración del sitio > Extensiones** aparece: "Se han detectado permisos no válidos al tratar de crear un directorio"
- Con depuración activa muestra: `/tmp/requestdir/... can not be created, check permissions. Error code: invaliddatarootpermissions`

**Causa**:
- El directorio `/tmp/requestdir` fue creado por `root` y `www-data` no puede escribir en él
- Esto ocurre cuando se ejecutan comandos de Moodle como `root` en lugar de `www-data`

**Solución**:

```bash
sudo chown -R www-data:www-data /tmp/requestdir
sudo chmod 750 /tmp/requestdir
```

> **Prevención**: Siempre ejecutar los comandos CLI de Moodle con `sudo -u www-data` para evitar que se creen directorios temporales como `root`.

### Moodle muy lento con 100 estudiantes

**Revisiones**:

1. Verificar consumo RAM: `free -h`
2. Verificar CPU: `htop`
3. Revisar logs Nginx: `/var/log/nginx/moodle_error.log`
4. Optimizar PHP-FPM: Aumentar `pm.max_children` en `/etc/php/8.4/fpm/pool.d/www.conf`

### El sistema no arranca después de actualización

**Si usaste Timeshift correctamente**:

1. Reiniciar el portátil
2. En GRUB, presionar `Shift` para ver menú de arranque
3. Seleccionar snapshot anterior de Timeshift
4. Restaurar snapshot completo desde GUI de Timeshift

---

# APÉNDICE C: Comandos de Verificación Rápida

```bash
# Ver si todos los servicios están corriendo
systemctl status nginx php8.4-fpm mariadb redis-server avahi-daemon

# Ver IP actual del servidor
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1'

# Ver logs en tiempo real (útil para debug)
sudo tail -f /var/log/nginx/moodle_error.log

# Ver consumo de recursos
free -h                    # RAM
df -h                      # Disco
top                        # CPU y procesos

# Verificar conectividad desde tablet (ejecutar en Windows)
ping moodle.local          # Debe responder
nslookup moodle.local      # Debe resolver IP

# Listar snapshots de Timeshift
sudo timeshift --list

# Probar conectividad del portátil al router
ping 192.168.1.1           # (Cambiar IP por la de tu router)
```

---

# APÉNDICE D: Checklist Pre-Clase

Imprime esta lista y márcala antes de ir al aula:

```
PREPARACIÓN EN CASA:
□ Backup manual de Moodle ejecutado hoy
□ Exámenes importados y configurados
□ Prueba de acceso a Moodle desde otro dispositivo
□ Portátil cargado al 100%
□ Cable ethernet RJ45 en la mochila

AL LLEGAR AL AULA:
□ Conectar cable RJ45 al router del aula
□ Encender portátil (si cifrado, ingresar contraseña)
□ Verificar que servicios arrancan (icono "Estado Moodle")
□ Anotar IP en la pizarra: http://moodle.local
□ Probar acceso desde 1 tablet antes de que entren estudiantes

DURANTE LA CLASE:
□ Monitor de recursos abierto (htop)
□ Logs de Nginx en otra terminal (opcional)

AL TERMINAR:
□ Click en "Backup Moodle" si hubo cambios importantes
□ Apagar correctamente (no cerrar la tapa directamente)
```

---

**Nota final**: Esta guía está diseñada para ser autocontenida y a prueba de fallos. Si encuentras errores o tienes dudas, consulta las fuentes oficiales listadas arriba o busca en [Debian Forums](https://forums.debian.net/).
