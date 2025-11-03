from typing import Callable

import streamlit as st


def render(on_start: Callable[[str], None]) -> None:
    # A common dark gray hex code
    DARK_GRAY_HEX = "#373737" 

    st.markdown(
        f'<h3 style="color: {DARK_GRAY_HEX};">1️⃣ Start Onboarding</h3>',
        unsafe_allow_html=True
    )
    st.markdown(
    f'<p style="font-size: small; color: {DARK_GRAY_HEX};">Kick things off so the crew can tailor your journey.</p>',
    unsafe_allow_html=True
    )

    st.markdown("<p style='color:#373737; margin-top:0rem; margin-bottom:-30rem;'>Email or User ID</p>", unsafe_allow_html=True)
    st.text_input("", key="user_id", placeholder="e.g. alex.lee@example.com")

    start_clicked = st.button(
        "Start Onboarding",
        type="primary",
        use_container_width=True,
    )

    if start_clicked:
        user_id = st.session_state.get("user_id", "").strip()
        if not user_id:
            st.warning("Please provide an email or ID to get started.")
            return
        on_start(user_id)
