import streamlit as st
from src.components.header import header_home
from src.components.footer import footer_home
from src.ui.base_layout import style_base_layout, style_background_home


def home_screen():
    style_background_home()
    style_base_layout()
    header_home()

    st.markdown("<div style='height:12px'></div>", unsafe_allow_html=True)

    col1, col2, col3 = st.columns([1, 2, 1], gap="large")

    with col2:
        st.markdown("""
            <div style="margin-bottom:8px; text-align: center;">
                <div style="font-size:3rem; margin-bottom:4px;">🏢</div>
                <div style="font-family:'Inter',sans-serif; font-size:1.5rem;
                     font-weight:700; color:#fff; margin-bottom:6px;">Company Portal</div>
                <div style="font-family:'Inter',sans-serif; font-size:1rem;
                     color:rgba(255,255,255,0.7); line-height:1.5; margin-bottom:16px;">
                     Manage teams, projects & records.<br>AI-powered HR tools.
                </div>
            </div>
        """, unsafe_allow_html=True)
        if st.button('Login as Admin  →', type='primary',
                     use_container_width=True, key='comp_btn'):
            st.session_state['login_type'] = 'company'
            st.rerun()

    footer_home()