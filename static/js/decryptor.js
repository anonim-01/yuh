(function () {
    "use strict";

    const decoder = new TextDecoder();

    function base64ToBytes(value) {
        const binaryString = globalThis.atob(value);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i += 1) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes;
    }

    async function decryptPayload(ciphertext, iv, key) {
        const cryptoKey = await globalThis.crypto.subtle.importKey(
            "raw",
            key,
            { name: "AES-GCM" },
            false,
            ["decrypt"],
        );
        const buffer = await globalThis.crypto.subtle.decrypt(
            { name: "AES-GCM", iv },
            cryptoKey,
            ciphertext,
        );
        return decoder.decode(buffer);
    }

    async function hydrate() {
        const root = document.getElementById("encrypted-root");
        if (!root) {
            return;
        }
        try {
            const html = await decryptPayload(
                base64ToBytes(root.dataset.ciphertext || ""),
                base64ToBytes(root.dataset.iv || ""),
                base64ToBytes(root.dataset.key || ""),
            );
            document.body.classList.remove("is-encrypted");
            document.documentElement.classList.add("is-decrypted");
            
            // Modern yöntem: innerHTML kullan ve script'leri manuel çalıştır
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            
            // Script etiketlerini bul ve yeniden oluştur (böylece çalışırlar)
            const scripts = tempDiv.querySelectorAll('script');
            
            // Body'yi temizle
            document.body.innerHTML = '';
            
            // Script olmayan içeriği ekle
            const fragment = document.createDocumentFragment();
            Array.from(tempDiv.childNodes).forEach(node => {
                if (node.nodeType === Node.ELEMENT_NODE && node.tagName === 'SCRIPT') {
                    // Script'leri sonra ekleyeceğiz
                    return;
                }
                fragment.appendChild(node.cloneNode(true));
            });
            document.body.appendChild(fragment);
            
            // Script'leri sırayla callback chain ile yükle
            let currentIndex = 0;
            
            const loadNextScript = () => {
                if (currentIndex >= scripts.length) return;
                
                const oldScript = scripts[currentIndex++];
                const newScript = document.createElement('script');
                
                // Tüm attribute'ları kopyala
                Array.from(oldScript.attributes).forEach(attr => {
                    newScript.setAttribute(attr.name, attr.value);
                });
                
                if (oldScript.src) {
                    // External script - yüklenince bir sonrakini yükle
                    newScript.onload = loadNextScript;
                    newScript.onerror = loadNextScript;
                } else {
                    // Inline script
                    newScript.textContent = oldScript.textContent;
                    // Inline script'ler senkron çalışır, sonrakini tetikle
                    setTimeout(loadNextScript, 0);
                }
                
                document.body.appendChild(newScript);
            };
            
            // İlk script'i yükle
            loadNextScript();
            
        } catch (error) {
            console.error("Encrypted payload could not be decrypted", error);
            document.body.classList.add("encryption-error");
            root.hidden = false;
            root.innerHTML = "<p>Şifreli içerik çözümlenemedi. Lütfen sayfayı yenileyin.</p>";
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", hydrate, { once: true });
    } else {
        void hydrate();
    }
})();
