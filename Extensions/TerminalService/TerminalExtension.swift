//
//  TerminalExtension.swift
//  Code
//
//  Created by Ken Chung on 15/11/2022.
//

import SwiftUI

class TerminalExtension: CodeAppExtension {
    override func onInitialize(app: MainApp, contribution: CodeAppExtension.Contribution) {
        let panel = Panel(
            labelId: "TERMINAL",
            mainView: AnyView(TerminalView()),
            toolBarView: AnyView(ToolbarView())
        )
        contribution.panel.registerPanel(panel: panel)
    }
}

private struct ToolbarView: View {
    @EnvironmentObject var App: MainApp

    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    App.terminalInstance.sendInterrupt()
                },
                label: {
                    Text("^C")
                }
            ).keyboardShortcut("c", modifiers: [.control])

            Button(
                action: {
                    App.terminalInstance.reset()
                },
                label: {
                    Image(systemName: "trash")
                }
            ).keyboardShortcut("k", modifiers: [.command])
        }
    }
}

private struct _TerminalView: UIViewRepresentable {
    var implementation: TerminalInstance

    @EnvironmentObject var App: MainApp

    private func injectBarButtons(webView: WebViewBase) {
        let toolbar = UIHostingController(
            rootView: TerminalKeyboardToolBar().environmentObject(App))
        toolbar.view.frame = CGRect(
            x: 0, y: 0, width: (webView.bounds.width), height: 40)

        webView.addInputAccessoryView(toolbar: toolbar.view)
    }

    private func removeBarButtons(webView: WebViewBase) {
        webView.addInputAccessoryView(toolbar: UIView.init())
    }

    func makeUIView(context: Context) -> UIView {
        if implementation.options.toolbarEnabled {
            injectBarButtons(webView: implementation.webView)
        }
        return implementation.webView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if implementation.options.toolbarEnabled {
            injectBarButtons(webView: implementation.webView)
        } else {
            removeBarButtons(webView: implementation.webView)
        }
    }

}

private struct TerminalView: View {
    @EnvironmentObject var App: MainApp
    @AppStorage("consoleFontSize") var consoleFontSize: Int = 14

    var body: some View {
        ZStack {
            _TerminalView(implementation: App.terminalInstance)
                .onTapGesture {
                    let notification = Notification(
                        name: Notification.Name("terminal.focus"),
                        userInfo: ["sceneIdentifier": App.sceneIdentifier]
                    )
                    NotificationCenter.default.post(notification)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: Notification.Name("editor.focus"),
                        object: nil),
                    perform: { notification in
                        App.terminalInstance.blur()
                    }
                )
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: Notification.Name("terminal.focus"),
                        object: nil),
                    perform: { notification in
                        guard
                            let sceneIdentifier = notification.userInfo?["sceneIdentifier"]
                                as? UUID,
                            sceneIdentifier != App.sceneIdentifier
                        else { return }
                        App.terminalInstance.blur()
                    }
                )
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        App.terminalInstance.executeScript("fitAddon.fit()")
                    }
                })
        }
        .foregroundColor(.clear)
    }
}
