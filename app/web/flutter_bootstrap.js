{{flutter_js}}
{{flutter_build_config}}

// Sem o service worker do Flutter (descontinuado): ele guardava versões antigas do site em cache e escondia
// as correções. Remove o que um build anterior tenha registrado neste navegador.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then((registros) => registros.forEach((r) => r.unregister()));
}
if ('caches' in window) {
  caches.keys().then((nomes) => nomes.filter((n) => n.startsWith('flutter')).forEach((n) => caches.delete(n)));
}

_flutter.loader.load();
