# -*- mode: python ; coding: utf-8 -*-
import platform

a = Analysis(
    ['src/__main__.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='trayce',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='trayce',
)

# Mac OS X Bundle
if platform.system() == 'Darwin':
    app = BUNDLE(
        coll,
        name='trayce.app',
        icon='icon.icns',
        bundle_identifier='trayce.trayce',
        info_plist={
            'LSBackgroundOnly': False
        }
    )
