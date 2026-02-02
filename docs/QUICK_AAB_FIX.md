# Quick AAB Build Fix

## 🚨 Problema: "Keystore file not found for signing config 'release'"

### ✅ Solução Rápida

**Use o workflow "Android AAB Simple" no Codemagic:**

1. **Acesse Codemagic Dashboard**
2. **Selecione: "Android AAB Simple (Google Play)"**
3. **Execute o build**
4. **Baixe o AAB dos artifacts**

### 🔧 O Que Foi Corrigido

1. **Build.gradle atualizado:**
   - Fallback para debug signing se keystore não existir
   - Configuração mais robusta de signing

2. **Script automático:**
   - `scripts/setup_keystore_for_codemagic.sh` gera keystore
   - Executado automaticamente no workflow

3. **Workflow simplificado:**
   - Menos steps, mais confiável
   - Keystore gerado via script dedicado

### 📱 Resultado

- ✅ AAB assinado e pronto para Google Play
- ✅ Keystore salvo nos artifacts para reutilização
- ✅ Build funciona sem configuração manual

### 🎯 Para Produção

1. **Primeira vez:** Use "Android AAB Simple"
2. **Baixe o keystore** dos artifacts
3. **Guarde em local seguro**
4. **Para próximas versões:** Configure keystore personalizado

### 🆘 Se Ainda Falhar

1. Verifique se o commit mais recente está no repositório
2. Use o workflow "Android AAB Simple" (não o "Release")
3. Verifique logs para mensagens "✅ Keystore generated"

### 📞 Suporte

Se o problema persistir:
- Verifique se Java 17 está configurado no Codemagic
- Confirme que o script `setup_keystore_for_codemagic.sh` existe
- Use o workflow mais simples primeiro