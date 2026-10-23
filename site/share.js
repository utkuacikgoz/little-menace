// "Send it to your iPhone" from a computer: the system share sheet (AirDrop, Messages) where there is one,
// otherwise copy the link.
(() => {
  const url = 'https://apps.apple.com/app/id6816104570';
  const data = { title: 'Little Menace', text: 'A pocket pet that holds a grudge.', url };
  const canShare = !!navigator.share && (!navigator.canShare || navigator.canShare(data));
  const mac = /Mac/.test(navigator.userAgentData?.platform || navigator.platform || '');
  document.querySelectorAll('[data-share]').forEach(button => {
    const label = button.querySelector('.share-label') || button;
    const idle = canShare ? (mac ? 'AirDrop it to your iPhone' : 'Share the link') : 'Copy the link';
    label.textContent = idle;
    button.addEventListener('click', async () => {
      if (canShare) {
        try { await navigator.share(data); } catch {}
        return;
      }
      try {
        await navigator.clipboard.writeText(url);
        label.textContent = 'Copied. Paste it into Messages.';
      } catch {
        label.textContent = url;
      }
      setTimeout(() => { label.textContent = idle; }, 2600);
    });
  });
})();
