import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'assets_download.sh'


class AssetDownloadTests(unittest.TestCase):
    def run_download(self, curl_body):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            shutil.copy(SCRIPT, root / 'assets_download.sh')
            target = root / 'assets/db/avonet.db'
            target.parent.mkdir(parents=True)
            target.write_bytes(b'previous usable file')
            mock_bin = root / 'bin'
            mock_bin.mkdir()
            curl = mock_bin / 'curl'
            curl.write_text('#!/usr/bin/env bash\n' + curl_body)
            curl.chmod(0o755)
            env = dict(os.environ, PATH=str(mock_bin) + os.pathsep + os.environ['PATH'])
            result = subprocess.run(['bash', str(root / 'assets_download.sh')],
                                    env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(target.read_bytes(), b'previous usable file')
            self.assertEqual(list(target.parent.glob('*.download.*')), [])
            return result

    def test_http_failure_preserves_existing_asset(self):
        result = self.run_download('exit 22\n')
        self.assertEqual(result.returncode, 22)

    def test_wrong_checksum_preserves_existing_asset(self):
        result = self.run_download('''while [[ $# -gt 0 ]]; do
  if [[ "$1" == '--output' ]]; then
    printf 'corrupt download' > "$2"
    exit 0
  fi
  shift
done
exit 2
''')
        self.assertIn('Checksum mismatch', result.stderr)


if __name__ == '__main__':
    unittest.main()
