/*!
 * Copyright (c) 2016 J-P Nurmi
 * Copyright (c) 2022 Emeric Grange
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "MobileUI_private.h"

#include <QtAndroid>

/* ************************************************************************** */

// WindowManager.LayoutParams
#define FLAG_KEEP_SCREEN_ON                     0x00000080
#define FLAG_TRANSLUCENT_STATUS                 0x04000000
#define FLAG_TRANSLUCENT_NAVIGATION             0x08000000
#define FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS       0x80000000

// View
#define SYSTEM_UI_FLAG_LAYOUT_STABLE            0x00000100
#define SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION   0x00000200
#define SYSTEM_UI_FLAG_LIGHT_STATUS_BAR         0x00002000
#define SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR     0x00000010

// UI modes
#define UI_MODE_NIGHT_UNDEFINED                 0x00000000
#define UI_MODE_NIGHT_NO                        0x00000010
#define UI_MODE_NIGHT_YES                       0x00000020
#define UI_MODE_NIGHT_MASK                      0x00000030

// WindowInsetsController
#define APPEARANCE_OPAQUE_STATUS_BARS           0x00000001
#define APPEARANCE_OPAQUE_NAVIGATION_BARS       0x00000002
#define APPEARANCE_LOW_PROFILE_BARS             0x00000004
#define APPEARANCE_LIGHT_STATUS_BARS            0x00000008
#define APPEARANCE_LIGHT_NAVIGATION_BARS        0x00000010
#define APPEARANCE_SEMI_TRANSPARENT_STATUS_BARS 0x00000020
#define APPEARANCE_SEMI_TRANSPARENT_NAVIGATION_BARS 0x0030

/* ************************************************************************** */

bool MobileUIPrivate::isAvailable_sys()
{
    return (QtAndroid::androidSdkVersion() >= 21);
}

static bool isQColorLight(QColor color)
{
    double darkness = 1.0 - (0.299 * color.red() + 0.587 * color.green() + 0.114 * color.blue()) / 255.0;
    return (darkness < 0.2);
}

static QAndroidJniObject getAndroidWindow()
{
    QAndroidJniObject window = QtAndroid::androidActivity().callObjectMethod("getWindow", "()Landroid/view/Window;");

    window.callMethod<void>("addFlags", "(I)V", FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
    window.callMethod<void>("clearFlags", "(I)V", FLAG_TRANSLUCENT_STATUS);

    return window;
}

static QAndroidJniObject getDisplayCutout()
{
    // DisplayCutout has been added in API level 28

    QAndroidJniObject window = QtAndroid::androidActivity().callObjectMethod("getWindow", "()Landroid/view/Window;");
    QAndroidJniObject decorview = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
    QAndroidJniObject insets = decorview.callObjectMethod("getRootWindowInsets", "()Landroid/view/WindowInsets;");
    QAndroidJniObject cutout = insets.callObjectMethod("getDisplayCutout", "()Landroid/view/DisplayCutout;");

    return cutout;
}

/* ************************************************************************** */

int MobileUIPrivate::getDeviceTheme_sys()
{
    QAndroidJniObject activity = QtAndroid::androidActivity();
    QAndroidJniObject rsc = activity.callObjectMethod("getResources", "()Landroid/content/res/Resources;");
    QAndroidJniObject conf = rsc.callObjectMethod("getConfiguration", "()Landroid/content/res/Configuration;");

    int uiMode = (conf.getField<int>("uiMode") & UI_MODE_NIGHT_MASK);

    return (uiMode == UI_MODE_NIGHT_YES) ? MobileUI::Theme::Dark : MobileUI::Theme::Light;
}

/* ************************************************************************** */

void MobileUIPrivate::setColor_statusbar(const QColor &color)
{
    if (QtAndroid::androidSdkVersion() < 21) return;

    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();
        window.callMethod<void>("setStatusBarColor", "(I)V", color.rgba());
    });

    if (QtAndroid::androidSdkVersion() < 23) return;

    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();
        QAndroidJniObject view = window.callObjectMethod("getDecorView", "()Landroid/view/View;");

        int visibility = view.callMethod<int>("getSystemUiVisibility", "()I");
        if (isQColorLight(color))
            visibility |= SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
        else
            visibility &= ~SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;

        view.callMethod<void>("setSystemUiVisibility", "(I)V", visibility);
    });
}

void MobileUIPrivate::setTheme_statusbar(MobileUI::Theme theme)
{
    if (QtAndroid::androidSdkVersion() < 23) return;

    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();
        if (QtAndroid::androidSdkVersion() < 30)
        {
            // Added in API level 23
            // Deprecated in API level 30

            QAndroidJniObject view = window.callObjectMethod("getDecorView", "()Landroid/view/View;");

            int visibility = view.callMethod<int>("getSystemUiVisibility", "()I");
            if (theme == MobileUI::Theme::Light)
                visibility |= SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
            else
                visibility &= ~SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;

            view.callMethod<void>("setSystemUiVisibility", "(I)V", visibility);
        }
        else if (QtAndroid::androidSdkVersion() >= 30)
        {
            // Added in API level 30

            QAndroidJniObject inset = window.callObjectMethod("getInsetsController",
                                                              "()Landroid/view/WindowInsetsController;");

            int visibility = inset.callMethod<int>("getSystemBarsAppearance", "()I");
            if (theme == MobileUI::Theme::Light)
                visibility |= APPEARANCE_LIGHT_STATUS_BARS;
            else
                visibility &= ~APPEARANCE_LIGHT_STATUS_BARS;

            inset.callMethod<void>("setSystemBarsAppearance", "(II)V",
                                   visibility, APPEARANCE_LIGHT_STATUS_BARS);
        }
    });
}

/* ************************************************************************** */

void MobileUIPrivate::setColor_navbar(const QColor &color)
{
    if (QtAndroid::androidSdkVersion() < 21) return;

    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();
        window.callMethod<void>("setNavigationBarColor", "(I)V", color.rgba());
    });

    if (QtAndroid::androidSdkVersion() < 23) return;

    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();
        QAndroidJniObject view = window.callObjectMethod("getDecorView", "()Landroid/view/View;");

        int visibility = view.callMethod<int>("getSystemUiVisibility", "()I");
        if (isQColorLight(color))
            visibility |= SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
        else
            visibility &= ~SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
        view.callMethod<void>("setSystemUiVisibility", "(I)V", visibility);
    });
}

void MobileUIPrivate::setTheme_navbar(MobileUI::Theme theme)
{
    if (QtAndroid::androidSdkVersion() < 23) return;

    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();
        QAndroidJniObject view = window.callObjectMethod("getDecorView", "()Landroid/view/View;");

        int visibility = view.callMethod<int>("getSystemUiVisibility", "()I");
        if (theme == MobileUI::Theme::Light)
            visibility |= SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
        else
            visibility &= ~SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
        view.callMethod<void>("setSystemUiVisibility", "(I)V", visibility);
    });
}

/* ************************************************************************** */

int MobileUIPrivate::getStatusbarHeight()
{
    return 24;
}

int MobileUIPrivate::getNavbarHeight()
{
    return 48;
}

int MobileUIPrivate::getSafeAreaTop()
{
    if (QtAndroid::androidSdkVersion() >= 28)
    {
        QAndroidJniObject cutout = getDisplayCutout();
        if (cutout.isValid())
        {
            return cutout.callMethod<int>("getSafeInsetTop", "()I") / qApp->devicePixelRatio();
        }
    }

    return 0;
}

int MobileUIPrivate::getSafeAreaLeft()
{
    if (QtAndroid::androidSdkVersion() >= 28)
    {
        QAndroidJniObject cutout = getDisplayCutout();
        if (cutout.isValid())
        {
            return cutout.callMethod<int>("getSafeInsetLeft", "()I") / qApp->devicePixelRatio();
        }
    }

    return 0;
}

int MobileUIPrivate::getSafeAreaRight()
{
    if (QtAndroid::androidSdkVersion() >= 28)
    {
        QAndroidJniObject cutout = getDisplayCutout();
        if (cutout.isValid())
        {
            return cutout.callMethod<int>("getSafeInsetRight", "()I") / qApp->devicePixelRatio();
        }
    }

    return 0;
}

int MobileUIPrivate::getSafeAreaBottom()
{
    if (QtAndroid::androidSdkVersion() >= 28)
    {
        QAndroidJniObject cutout = getDisplayCutout();
        if (cutout.isValid())
        {
            return cutout.callMethod<int>("getSafeInsetBottom", "()I") / qApp->devicePixelRatio();
        }
    }

    return 0;
}

/* ************************************************************************** */

bool MobileUIPrivate::isScreenkeepOn()
{
    return false; // TODO
}

void MobileUIPrivate::keepScreenOn(bool on)
{
    QtAndroid::runOnAndroidThread([=]() {
        QAndroidJniObject window = getAndroidWindow();

        if (on)
            window.callMethod<void>("addFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
        else
            window.callMethod<void>("clearFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
    });
}

/* ************************************************************************** */

void MobileUIPrivate::refresh()
{
    if (QNativeInterface::QAndroidApplication::sdkVersion() >= 30)
    {
        setTheme_statusbar(MobileUIPrivate::statusbarTheme);
    }
}

/* ************************************************************************** */
