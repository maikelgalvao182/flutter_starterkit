/**
 * Script para migrar notificações antigas
 * Adiciona campo n_receiver_id baseado no userId existente
 */

const admin = require('firebase-admin');
const serviceAccount = require('../partiu-479902-firebase-adminsdk-i1k2l-bc9eb42d13.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateNotifications() {
  console.log('🔄 Iniciando migração de notificações...');
  
  try {
    // Buscar notificações que têm userId mas não têm n_receiver_id
    const snapshot = await db.collection('Notifications')
      .where('userId', '!=', null)
      .get();
    
    console.log(`📊 Total de notificações: ${snapshot.size}`);
    
    const batch = db.batch();
    let updateCount = 0;
    let skipCount = 0;
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Se já tem n_receiver_id, pular
      if (data.n_receiver_id) {
        skipCount++;
        continue;
      }
      
      // Se tem userId, adicionar n_receiver_id
      if (data.userId) {
        batch.update(doc.ref, {
          n_receiver_id: data.userId
        });
        updateCount++;
        
        if (updateCount % 100 === 0) {
          console.log(`📝 Processadas: ${updateCount}`);
        }
      }
    }
    
    if (updateCount > 0) {
      await batch.commit();
      console.log(`✅ Migração completa!`);
      console.log(`   - Atualizadas: ${updateCount}`);
      console.log(`   - Ignoradas: ${skipCount}`);
    } else {
      console.log(`ℹ️  Nenhuma notificação para migrar`);
    }
    
  } catch (error) {
    console.error('❌ Erro na migração:', error);
  } finally {
    process.exit(0);
  }
}

migrateNotifications();
