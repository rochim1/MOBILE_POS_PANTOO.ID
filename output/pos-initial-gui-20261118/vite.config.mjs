import makeConfig from '../../../front_end_template/vite.config.js';
import { fileURLToPath } from 'node:url';
export default context => ({ ...makeConfig(context), cacheDir: fileURLToPath(new URL('./vite-cache', import.meta.url)) });
