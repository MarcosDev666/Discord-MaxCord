# MaxCord para Android

Base de una app de comunidades para Android, creada con Expo y Supabase. Incluye registro e inicio de sesión por correo, servidores con códigos de invitación, canales de texto, mensajes en tiempo real, distintivos de rol y eliminación de mensajes propios o por staff. Mantén pulsado un mensaje para eliminarlo.

## Configuración

1. Crea un proyecto en [Supabase](https://supabase.com), y ejecuta una única vez `supabase/schema.sql` en su editor SQL. La publicación Realtime debe estar habilitada para `messages`.
2. En Authentication configura el proveedor de correo. Con confirmación activada, cada usuario debe verificar su correo antes de entrar. Para un servicio real configura SMTP y las URL de autenticación en Supabase.
3. Copia `.env.example` a `.env` y completa la URL y la clave **anon/publishable** del proyecto. No uses la clave `service_role` en la app.
4. Ejecuta `npm install` y `npx expo start`; abre el QR con Expo Go en Android. Para el emulador, ejecuta `npm run android`.
5. Para un APK instalable, configura una cuenta de Expo/EAS y ejecuta `npx eas-cli build -p android --profile preview`. Para publicar en Play Store usa el perfil `production` (AAB), configura firma y cuenta de desarrollador. Las variables `EXPO_PUBLIC_SUPABASE_URL` y `EXPO_PUBLIC_SUPABASE_ANON_KEY` también deben estar disponibles en el entorno de EAS.

El esquema activa RLS y controla el acceso a datos por membresía. El código de invitación se muestra a los miembros del servidor, así que cualquiera de ellos puede compartirlo. El rol `staff` se puede asignar por un administrador desde el panel de Supabase; aún no hay interfaz de gestión de roles. Los mensajes están limitados a los 100 más recientes por canal.

## Alcance y producción

Esta es una base funcional, no un reemplazo completo de Discord ni una aplicación auditada para producción. **No incluye llamadas de voz/video**, notificaciones push, mensajes directos, subida de archivos, recuperación de contraseña, bloqueo/expulsión, gestión de roles desde la app ni insignias personalizadas. Antes de abrirla al público hacen falta, entre otras cosas, moderación y reportes, limitación de abuso, privacidad y términos, pruebas de seguridad, copias de seguridad y pruebas en dispositivos. Las llamadas necesitan además infraestructura WebRTC/TURN y señalización. Vercel no distribuye aplicaciones Android: se puede usar para servicios web auxiliares, mientras que el APK/AAB se genera con EAS.

## Versión web y Vercel

La versión web utiliza la misma aplicación y el mismo proyecto Supabase que Android. `public/index.html` es la plantilla HTML que Expo usa al compilar; no funciona abriéndola directamente como archivo, porque el código de la aplicación se agrega durante la compilación.

- Para desarrollo: configura `.env` como se indicó arriba y ejecuta `npm run web`.
- Para generar el sitio estático: ejecuta `npm run build:web`. El resultado, incluido `index.html`, queda en `dist/`; sírvelo con un servidor HTTP.
- En Vercel importa el repositorio y configura `EXPO_PUBLIC_SUPABASE_URL` y `EXPO_PUBLIC_SUPABASE_ANON_KEY` en las variables de entorno **antes de desplegar**. `vercel.json` configura el comando y la carpeta de salida. Estas variables se incluyen en el código público: utiliza exclusivamente la clave anon/publishable y mantén RLS activado.
- En Supabase Authentication > URL Configuration, configura la Site URL con la URL de Vercel y añade las URLs de despliegue autorizadas a Redirect URLs para la confirmación de correo.

En web puedes eliminar mensajes con el botón «Eliminar»; en Android, mantén pulsado el mensaje. Esta versión comparte las limitaciones enumeradas anteriormente.
