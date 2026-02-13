const express = require('express');
const router = express.Router();
const { 
  getTodos, getTodo, createTodo, 
  updateTodo, deleteTodo, toggleTodo 
} = require('../controllers/todoController');
const { protect } = require('../middleware/auth');

/**
 * @swagger
 * tags:
 *   name: Todos
 *   description: Görev yönetimi ve hatırlatıcı işlemleri
 */

// Tüm Todo rotaları korumalıdır
router.use(protect);

/**
 * @swagger
 * /api/todos:
 *   get:
 *     summary: Giriş yapmış kullanıcının tüm görevlerini listeler
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Görev listesi başarıyla getirildi
 *   post:
 *     summary: Yeni bir görev oluşturur
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *                 example: "Market Alışverişi"
 *               description:
 *                 type: string
 *                 example: "Süt, ekmek ve yumurta alınacak"
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high]
 *                 default: medium
 *               dueDate:
 *                 type: string
 *                 format: date-time
 *                 example: "2026-02-15T14:30:00Z"
 *     responses:
 *       201:
 *         description: Görev başarıyla oluşturuldu
 */
router.route('/').get(getTodos).post(createTodo);

/**
 * @swagger
 * /api/todos/{id}:
 *   get:
 *     summary: Belirli bir görevin detayını getirir
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Görev ID'si
 *     responses:
 *       200:
 *         description: Görev detayı getirildi
 *   put:
 *     summary: Bir görevi günceller
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               priority:
 *                 type: string
 *                 enum: [low, medium, high]
 *               dueDate:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       200:
 *         description: Güncelleme başarılı
 *   delete:
 *     summary: Bir görevi siler
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Silme işlemi başarılı
 */
router.route('/:id').get(getTodo).put(updateTodo).delete(deleteTodo);

/**
 * @swagger
 * /api/todos/{id}/toggle:
 *   patch:
 *     summary: Görevin tamamlanma durumunu değiştirir (done/undone)
 *     tags: [Todos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Durum başarıyla değiştirildi
 */
router.patch('/:id/toggle', toggleTodo);

module.exports = router;