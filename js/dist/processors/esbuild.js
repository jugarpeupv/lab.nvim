/*

lab.nvim
Copyright: (c) 2022, Dan Peterson <hi@dan-peterson.ca>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/
import esbuild from 'esbuild';
import path from 'node:path';
import fs from 'node:fs/promises';
import os from 'node:os';
import { logger } from '../util/logging.js';
const log = logger('esbuild');
export default async (filePath) => {
    try {
        const fileName = path.basename(filePath).replace(path.extname(filePath), '.js');
        const tmpPath = await fs.realpath(os.tmpdir());
        const outPath = path.join(tmpPath, fileName);
        log(outPath);
        esbuild.buildSync({
            entryPoints: [filePath],
            sourcemap: true,
            bundle: true,
            platform: 'node',
            target: ['es2020'],
            outfile: outPath,
            logLevel: 'silent',
        });
        return outPath;
    }
    catch (err) {
        throw new Error('esbuild failed');
    }
};