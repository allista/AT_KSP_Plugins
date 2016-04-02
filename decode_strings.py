'''
Created on Feb 14, 2016

@author: Allis Tauri <allista@gmail.com>
'''

import re, os
from subprocess import Popen, PIPE
from BioUtils.Tools.Multiprocessing import parallelize_work, MPMain

api_dir = u'/home/storage/Games/KSP_linux/PluginsArchives/Development/KSP_API'
str_re = re.compile(r'([\n\r]*.\((\d+)\))')
nl_re = re.compile(r'[\n\r]+')

decoder_dir = u'/home/storage/Games/KSP_linux/PluginsArchives/Development/CleanAPI/DecodeResources/bin/Release'
decoder = 'DecodeResources.exe'

class Main(MPMain):
    @staticmethod
    def decode_string(code):
        os.chdir(decoder_dir)
        try:
            process = Popen('mono %s %s' % (decoder, code),
                            stdout=PIPE, stderr=PIPE, shell=True)
            process.wait()
            if process.returncode != 0 and process.stderr: 
                print process.stderr.read()
                print
            return nl_re.sub(' ', process.stdout.read())
        except Exception, e:
            print e
            return 'String not found'

    def _main(self):
        files = []
        for dirpath, _dirnames, filenames in os.walk(api_dir):
            for filename in filenames:
                if not filename.endswith('.cs'): continue
                files.append(os.path.join(dirpath, filename))
    
        def worker(filepath):
            with open(filepath, 'rb') as inp:
                text = inp.read()
            matches = str_re.findall(text)
            if not matches: return
            decoded = set()
            for _match, code in matches:
                if code in decoded: continue
                code_str = '"%s"' % self.decode_string(code)
                text = re.sub(r'[\n\r]*.\(%s\)' % code, code_str, text)
                decoded.add(code)
            with open(filepath, 'wb') as out:
                out.write(text)
        
        parallelize_work(self.abort_event, True, 1, worker, files)
        print 'Done'
        return 0
    
if __name__ == '__main__':
    Main(run=True)