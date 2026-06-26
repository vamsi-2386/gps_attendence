import sys
import os

# Ensure the 'app' directory is in the Python path so Streamlit Cloud can find 'src'
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import streamlit as st
from PIL import Image

from src.screens.home_screen import home_screen
from src.screens.company_screen import company_screen

# Defensive: an optional UI helper must never take down the whole app. Streamlit
# Cloud sometimes re-runs the script against a stale cached module after a
# redeploy; if the symbol is briefly missing we fall back to a no-op so the app
# still boots (a Reboot then loads the real one).
try:
    from src.ui.base_layout import desktop_only_guard
except Exception:
    def desktop_only_guard():
        return None

# Lumenor logo used as the browser tab / app icon. Falls back to an emoji if
# the asset is missing so the app never fails to boot.
_LOGO_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lumenor.png')
try:
    _PAGE_ICON = Image.open(_LOGO_PATH)
except Exception:
    _PAGE_ICON = '🟣'

def main():
    st.set_page_config(
        page_title='Lumenor HRMS',
        page_icon=_PAGE_ICON,
        # Wide layout gives the 10-tab admin dashboard (tables, charts, the
        # office map) room to breathe; the landing page stays centered via its
        # own [1,2,1] column split.
        layout="wide",
    )

    # Block phones/small screens with a "desktop only" notice.
    desktop_only_guard()

    if 'login_type' not in st.session_state:
        st.session_state['login_type'] = None

    match st.session_state['login_type']:
        case 'company':
            company_screen()
        case None:
            home_screen()

main()