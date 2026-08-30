import { Router } from 'express';
import { registerOwner, login } from '../controllers/authController';

const router = Router();

router.post('/register-owner', registerOwner);
router.post('/login', login);

export default router;
